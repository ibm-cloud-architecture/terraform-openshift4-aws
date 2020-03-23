locals {
#  infrastructure_id = "${var.infrastructure_id != "" ? "${var.infrastructure_id}" : "${var.clustername}-${random_id.clusterid.hex}"}"
  infrastructure_id = var.infrastructure_id
}

resource "null_resource" "openshift_installer" {
  provisioner "local-exec" {
    command = <<EOF
case $(uname -s) in
  Linux)
    wget -r -l1 -np -nd ${var.openshift_installer_url} -P ${path.module} -A 'openshift-install-linux-4*.tar.gz'
    ;;
  Darwin)
    wget -r -l1 -np -nd ${var.openshift_installer_url} -P ${path.module} -A 'openshift-install-mac-4*.tar.gz'
    ;;
  *) exit 1
    ;;
esac
EOF
  }

  provisioner "local-exec" {
    command = "tar zxvf ${path.module}/openshift-install-*-4*.tar.gz -C ${path.module}"
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/openshift-install-*-4*.tar.gz ${path.module}/robots*.txt* ${path.module}/README.md"
  }
}

resource "null_resource" "openshift_client" {
  provisioner "local-exec" {
    command = <<EOF
case $(uname -s) in
  Linux)
    wget -r -l1 -np -nd ${var.openshift_installer_url} -P ${path.module} -A 'openshift-client-linux-4*.tar.gz'
    ;;
  Darwin)
    wget -r -l1 -np -nd ${var.openshift_installer_url} -P ${path.module} -A 'openshift-client-mac-4*.tar.gz'
    ;;
  *)
    exit 1
    ;;
esac
EOF
  }

  provisioner "local-exec" {
    command = "tar zxvf ${path.module}/openshift-client-*-4*.tar.gz -C ${path.module}"
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/openshift-client-*-4*.tar.gz ${path.module}/robots*.txt* ${path.module}/README.md"
  }
}

resource "null_resource" "aws_credentials" {
  provisioner "local-exec" {
    command = "mkdir -p ~/.aws"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.aws_credentials.rendered}' > ~/.aws/credentials"
  }
}

data "template_file" "aws_credentials" {
  template = <<-EOF
[default]
aws_access_key_id = ${var.aws_access_key_id}
aws_secret_access_key = ${var.aws_secret_access_key}
EOF
}


data "template_file" "install_config_yaml" {
  template = <<-EOF
apiVersion: v1
baseDomain: ${var.domain}
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 1
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: ${var.master_count}
metadata:
  name: ${var.clustername}
networking:
  clusterNetworks:
  - cidr: ${var.cluster_network_cidr}
    hostPrefix: ${var.cluster_network_host_prefix}
  machineCIDR:  ${var.vpc_cidr_block}
  networkType: OpenShiftSDN
  serviceNetwork:
  - ${var.service_network_cidr}
platform:
  aws:
    region: ${var.aws_region}
pullSecret: '${file(var.openshift_pull_secret)}'
sshKey: '${tls_private_key.installkey.public_key_openssh}'
%{if var.airgapped["enabled"]}imageContentSources:
- mirrors:
  - ${var.airgapped["repository"]}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${var.airgapped["repository"]}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
%{endif}
EOF
}


resource "local_file" "install_config" {
  content  =  data.template_file.install_config_yaml.rendered
  filename =  "${path.module}/install-config.yaml"
}

resource "null_resource" "generate_manifests" {
  triggers = {
    install_config =  data.template_file.install_config_yaml.rendered
  }

  depends_on = [
    local_file.install_config,
    null_resource.aws_credentials,
    null_resource.openshift_installer,
  ]

  provisioner "local-exec" {
    command = "rm -rf ${path.module}/temp"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/temp"
  }

  provisioner "local-exec" {
    command = "mv ${path.module}/install-config.yaml ${path.module}/temp"
  }

  provisioner "local-exec" {
    command = "${path.module}/openshift-install --dir=${path.module}/temp create manifests"
  }
}

# because we're providing our own control plane machines, remove it from the installer
resource "null_resource" "manifest_cleanup_control_plane_machineset" {
  depends_on = [
    null_resource.generate_manifests
  ]

  triggers = {
    install_config =  data.template_file.install_config_yaml.rendered
    local_file     =  local_file.install_config.id
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/temp/openshift/99_openshift-cluster-api_master-machines-*.yaml"
  }
}

# rewrite the domains and the infrastructure id we use in the cluster
resource "local_file" "cluster_infrastructure_config" {
  depends_on = [
    null_resource.generate_manifests
  ]
  file_permission = "0644"
  filename        =  "${path.module}/temp/manifests/cluster-infrastructure-02-config.yml"

  content = <<EOF
apiVersion: config.openshift.io/v1
kind: Infrastructure
metadata:
  creationTimestamp: null
  name: cluster
spec:
  cloudConfig:
    name: ""
status:
  apiServerInternalURI: https://api-int.${var.clustername}.${var.domain}:6443
  apiServerURL: https://api.${var.clustername}.${var.domain}:6443
  etcdDiscoveryDomain: ${var.clustername}.${var.domain}
  infrastructureName: ${local.infrastructure_id}
  platform: AWS
  platformStatus:
    aws:
      region: ${var.aws_region}
    type: AWS
EOF
}
# modify manifests/cluster-dns-02-config.yml
resource "null_resource" "manifest_cleanup_dns_config" {
  depends_on = [
    null_resource.generate_manifests
  ]

  triggers = {
    install_config =  data.template_file.install_config_yaml.rendered
    local_file     =  local_file.install_config.id
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/temp/manifests/cluster-dns-02-config.yml"
  }
}

#redo the dns config
resource "local_file" "dns_config" {
  count = var.airgapped.enabled ? 0 : 1
  depends_on = [
    null_resource.manifest_cleanup_dns_config
  ]

  file_permission = "0644"
  filename        = "${path.module}/temp/manifests/cluster-dns-02-config.yml"
  content         = <<EOF
apiVersion: config.openshift.io/v1
kind: DNS
metadata:
  creationTimestamp: null
  name: cluster
spec:
  baseDomain: ${var.clustername}.${var.domain}
  privateZone:
      tags:
        Name: ${local.infrastructure_id}-int
        kubernetes.io/cluster/${local.infrastructure_id}: owned
  publicZone:
    id: ${var.dns_public_id}
status: {}
EOF
}

# remove these machinesets, we will rewrite them using the security group and subnets that we created
resource "null_resource" "manifest_cleanup_worker_machineset" {
  depends_on = [
    null_resource.generate_manifests
  ]

  triggers = {
    install_config =  data.template_file.install_config_yaml.rendered
    local_file     =  local_file.install_config.id
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/temp/openshift/99_openshift-cluster-api_worker-machines*.yaml"
  }
}

#redo the worker machineset
resource "local_file" "worker_machineset" {
  count           = length(var.aws_worker_availability_zones)

  depends_on = [
    null_resource.manifest_cleanup_worker_machineset
  ]

  file_permission = "0644"
  filename        = "${path.module}/temp/openshift/99_openshift-cluster-api_worker-machineset-${count.index}.yaml"
  content         = <<EOF
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  creationTimestamp: null
  labels:
    machine.openshift.io/cluster-api-cluster: ${local.infrastructure_id}
  name: ${local.infrastructure_id}-worker-${element(var.aws_worker_availability_zones, count.index)}
  namespace: openshift-machine-api
spec:
  replicas: 1
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: ${local.infrastructure_id}
      machine.openshift.io/cluster-api-machineset: ${local.infrastructure_id}-worker-${element(var.aws_worker_availability_zones, count.index)}
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: ${local.infrastructure_id}
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: ${local.infrastructure_id}-worker-${element(var.aws_worker_availability_zones, count.index)}
    spec:
      metadata:
        creationTimestamp: null
      providerSpec:
        value:
          ami:
            id: ${var.ami}
          apiVersion: awsproviderconfig.openshift.io/v1beta1
          blockDevices:
          - ebs:
              iops: ${var.aws_worker_root_volume_iops}
              volumeSize: ${var.aws_worker_root_volume_size}
              volumeType: ${var.aws_worker_root_volume_type}
          credentialsSecret:
            name: aws-cloud-credentials
          deviceIndex: 0
          iamInstanceProfile:
            id: ${local.infrastructure_id}-worker-profile
          instanceType: ${var.aws_worker_instance_type}
          kind: AWSMachineProviderConfig
          metadata:
            creationTimestamp: null
          placement:
            availabilityZone: ${element(var.aws_worker_availability_zones, count.index)}
            region: ${var.aws_region}
          publicIp: null
          securityGroups:
          - filters:
            - name: tag:Name
              values:
              - ${local.infrastructure_id}-worker-sg
          subnet:
            filters:
            - name: tag:Name
              values:
              - ${local.infrastructure_id}-private-${element(var.aws_worker_availability_zones, count.index)}
          tags:
          - name: kubernetes.io/cluster/${local.infrastructure_id}
            value: owned
          userDataSecret:
            name: worker-user-data
EOF
}

#redo the worker machineset
resource "local_file" "ingresscontroller" {
  count           = var.airgapped.enabled ? 1 : 0

  depends_on = [
    null_resource.generate_manifests
  ]
  file_permission = "0644"
  filename = "${path.module}/temp/openshift/99_default_ingress_controller.yml"
  content = <<EOF
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: default
  namespace: openshift-ingress-operator
spec:
  replicas: 2
  endpointPublishingStrategy:
    type: Private
EOF
}

resource "local_file" "awssecrets1" {
  count           = var.airgapped.enabled ? 1 : 0

  depends_on = [
    null_resource.generate_manifests
  ]
  file_permission = "0644"
  filename        =  "${path.module}/temp/openshift/99_awssecrets_image_registry.yml"

  content = <<EOF
apiVersion: v1
data:
  aws_access_key_id: ${base64encode(var.aws_access_key_id)}
  aws_secret_access_key: ${base64encode(var.aws_secret_access_key)}
kind: Secret
metadata:
  name: installer-cloud-credentials
  namespace: openshift-image-registry
type: Opaque
EOF
}

resource "local_file" "awssecrets2" {
  count           = var.airgapped.enabled ? 1 : 0

  depends_on = [
    null_resource.generate_manifests
  ]
  file_permission = "0644"
  filename        =  "${path.module}/temp/openshift/99_awssecrets_ingress.yml"

  content = <<EOF
apiVersion: v1
data:
  aws_access_key_id: ${base64encode(var.aws_access_key_id)}
  aws_secret_access_key: ${base64encode(var.aws_secret_access_key)}
kind: Secret
metadata:
  name: cloud-credentials
  namespace: openshift-ingress-operator
type: Opaque
EOF
}

resource "local_file" "awssecrets3" {
  count           = var.airgapped.enabled ? 1 : 0

  depends_on = [
    null_resource.generate_manifests
  ]
  file_permission = "0644"
  filename        =  "${path.module}/temp/openshift/99_awssecrets_machine_api.yml"

  content = <<EOF
apiVersion: v1
data:
  aws_access_key_id: ${base64encode(var.aws_access_key_id)}
  aws_secret_access_key: ${base64encode(var.aws_secret_access_key)}
kind: Secret
metadata:
  name: aws-cloud-credentials
  namespace: openshift-machine-api
type: Opaque
EOF
}

# build the bootstrap ignition config
resource "null_resource" "generate_ignition_config" {
  depends_on = [
    null_resource.manifest_cleanup_control_plane_machineset,
    local_file.worker_machineset,
    local_file.dns_config,
    local_file.ingresscontroller,
    local_file.awssecrets1,
    local_file.awssecrets2,
    local_file.awssecrets3,
    local_file.airgapped_registry_upgrades,
    local_file.cluster_infrastructure_config,
  ]

  triggers = {
    install_config                   =  data.template_file.install_config_yaml.rendered
    local_file_install_config        =  local_file.install_config.id
    local_file_infrastructure_config =  local_file.cluster_infrastructure_config.id
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/temp"
  }

  provisioner "local-exec" {
    command = "rm -rf ${path.module}/temp/_manifests ${path.module}/temp/_openshift"
  }

  provisioner "local-exec" {
    command = "cp -r ${path.module}/temp/manifests ${path.module}/temp/_manifests"
  }

  provisioner "local-exec" {
    command = "cp -r ${path.module}/temp/openshift ${path.module}/temp/_openshift"
  }

  provisioner "local-exec" {
    command = "${path.module}/openshift-install --dir=${path.module}/temp create ignition-configs"
  }
}

resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${path.module}/temp"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/openshift-install"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/oc"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/kubectl"
  }
}

data "local_file" "bootstrap_ign" {
  depends_on = [
    null_resource.generate_ignition_config
  ]

  filename =  "${path.module}/temp/bootstrap.ign"
}

data "local_file" "master_ign" {
  depends_on = [
    null_resource.generate_ignition_config
  ]

  filename =  "${path.module}/temp/master.ign"
}

data "local_file" "worker_ign" {
  depends_on = [
    null_resource.generate_ignition_config
  ]

  filename =  "${path.module}/temp/worker.ign"
}

data "local_file" "cluster_infrastructure" {
  depends_on = [
    null_resource.generate_manifests
  ]

  filename =  "${path.module}/temp/manifests/cluster-infrastructure-02-config.yml"
}

resource "null_resource" "get_auth_config" {
  depends_on = [null_resource.generate_ignition_config]
  provisioner "local-exec" {
    when    = create
    command = "cp ${path.module}/temp/auth/* ${path.root}/ "
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm ${path.root}/kubeconfig ${path.root}/kubeadmin-password "
  }
}

resource "local_file" "airgapped_registry_upgrades" {
  count    = var.airgapped["enabled"] ? 1 : 0
  filename = "${path.module}/temp/openshift/99_airgapped_registry_upgrades.yaml"
  depends_on = [
    null_resource.generate_manifests,
  ]
  content  = <<EOF
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: airgapped
spec:
  repositoryDigestMirrors:
  - mirrors:
    - ${var.airgapped["repository"]}
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - ${var.airgapped["repository"]}
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF
}
