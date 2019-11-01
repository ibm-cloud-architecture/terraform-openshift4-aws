resource "null_resource" "openshift_installer" {
  provisioner "local-exec" {
    command = "wget -r -l1 -np -nd ${var.openshift_installer_url} -P ${path.module} -A 'openshift-install-linux-4*.tar.gz'"
  }

  provisioner "local-exec" {
    command = "tar zxvf ${path.module}/openshift-install-linux-4*.tar.gz -C ${path.module}"
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/openshift-install-linux-4*.tar.gz ${path.module}/robots*.txt*"
  }
}

resource "null_resource" "openshift_client" {
  depends_on = [
    "null_resource.openshift_installer"
  ]

  provisioner "local-exec" {
    command = "wget -r -l1 -np -nd ${var.openshift_installer_url} -P ${path.module} -A 'openshift-client-linux-4*.tar.gz'"
  }
  provisioner "local-exec" {
    command = "tar zxvf ${path.module}/openshift-client-linux-4*.tar.gz -C ${path.module}"
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/openshift-client-linux-4*.tar.gz ${path.module}/robots*.txt*"
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
  replicas: ${var.use_worker_machinesets ? lookup(var.worker, "count", 3) : 0}
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: ${lookup(var.control_plane, "count", 3)}
metadata:
  name: ${var.clustername}
networking:
  clusterNetworks:
  - cidr: ${var.cluster_network_cidr}
    hostPrefix: ${var.cluster_network_host_prefix}
  machineCIDR:  ${data.aws_vpc.ocp_vpc.cidr_block}
  networkType: OpenShiftSDN
  serviceNetwork:
  - ${var.service_network_cidr}
platform:
  aws:
    region: ${data.aws_region.current.name}
pullSecret: '${file(var.openshift_pull_secret)}'
sshKey: '${tls_private_key.installkey.public_key_openssh}'
EOF
}

resource "local_file" "install_config" {
  content = "${data.template_file.install_config_yaml.rendered}"
  filename = "${path.module}/install-config.yaml"
}

resource "null_resource" "generate_manifests" {
  triggers = {
    install_config = "${data.template_file.install_config_yaml.rendered}"
  }

  depends_on = [
    "local_file.install_config",
    "null_resource.aws_credentials",
    "null_resource.openshift_installer"
  ]

  provisioner "local-exec" {
    command = "rm -rf ${path.module}/${local.infrastructure_id}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/${local.infrastructure_id}"
  }

  provisioner "local-exec" {
    command = "mv ${path.module}/install-config.yaml ${path.module}/${local.infrastructure_id}"
  }

  provisioner "local-exec" {
    command = "${path.module}/openshift-install --dir=${path.module}/${local.infrastructure_id} create manifests"
  }
}

# because we're providing our own control plane machines, remove it from the installer
resource "null_resource" "manifest_cleanup_control_plane_machineset" {
  depends_on = [
    "null_resource.generate_manifests"
  ]

  triggers = {
    install_config = "${data.template_file.install_config_yaml.rendered}"
    local_file = "${local_file.install_config.id}"
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/${local.infrastructure_id}/openshift/99_openshift-cluster-api_master-machines-*.yaml"
  }
}

# remove these machinesets, we will rewrite them using the security group and subnets that we created
resource "null_resource" "manifest_cleanup_worker_machineset" {
  depends_on = [
    "null_resource.generate_manifests"
  ]

  triggers = {
    install_config = "${data.template_file.install_config_yaml.rendered}"
    local_file = "${local_file.install_config.id}"
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/${local.infrastructure_id}/openshift/99_openshift-cluster-api_worker-machines*.yaml"
  }
}

## Moving the machineset to the manifests dir
resource "local_file" "worker_machineset" {
  count = "${var.use_worker_machinesets ? length(var.aws_azs) : 0}"
  file_permission = "0644"
  depends_on = [
    "null_resource.manifest_cleanup_worker_machineset"
  ]

  filename = "${path.module}/${local.infrastructure_id}/openshift/99_openshift-cluster-api_worker-machineset-${count.index}.yaml"

  content = <<-EOF
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  creationTimestamp: null
  labels:
    machine.openshift.io/cluster-api-cluster: ${local.infrastructure_id}
  name: ${local.infrastructure_id}-worker-${element(data.aws_availability_zone.aws_azs.*.name, count.index)}
  namespace: openshift-machine-api
spec:
  replicas: ${floor(lookup(var.worker, "count", 3) / length(data.aws_availability_zone.aws_azs))}
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: ${local.infrastructure_id}
      machine.openshift.io/cluster-api-machineset: ${local.infrastructure_id}-worker-${element(data.aws_availability_zone.aws_azs.*.name, count.index)}
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: ${local.infrastructure_id}
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: ${local.infrastructure_id}-worker-${element(data.aws_availability_zone.aws_azs.*.name, count.index)}
    spec:
      metadata:
        creationTimestamp: null
      providerSpec:
        value:
          ami:
            id: ${data.aws_ami.rhcos.id}
          apiVersion: awsproviderconfig.openshift.io/v1beta1
          blockDevices:
          - ebs:
              iops: 0
              volumeSize: ${lookup(var.worker, "disk", 120)}
              volumeType: gp2
          credentialsSecret:
            name: aws-cloud-credentials
          deviceIndex: 0
          iamInstanceProfile:
            id: ${data.aws_iam_instance_profile.ocp_ec2_worker_instance_profile.name}
          instanceType: m4.large
          kind: AWSMachineProviderConfig
          metadata:
            creationTimestamp: null
          placement:
            availabilityZone: ${element(data.aws_availability_zone.aws_azs.*.name, count.index)}
            region: ${data.aws_region.current.name}
          publicIp: null
          securityGroups:
          - filters:
            - name: group-id
              values:
              - ${data.aws_security_group.worker.id}
          subnet:
            filters:
            - name: subnet-id
              values:
              - ${element(data.aws_subnet.ocp_pri_subnet.*.id, count.index)}
          tags:
          - name: kubernetes.io/cluster/${local.infrastructure_id}
            value: owned
          userDataSecret:
            name: worker-user-data
status:
  replicas: 0
EOF

}

# rewrite the domains and the infrastructure id we use in the cluster
resource "local_file" "cluster_infrastructure_config" {
  depends_on = [
    "null_resource.generate_manifests"
  ]
  file_permission = "0644"
  filename = "${path.module}/${local.infrastructure_id}/manifests/cluster-infrastructure-02-config.yml"

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
      region: ${data.aws_region.current.name}
    type: AWS
EOF
}

# remove public DNS domain management, just manage the private hosted zone
resource "local_file" "cluster_dns_config" {
  depends_on = [
    "null_resource.generate_manifests"
  ]
  file_permission = "0644"
  filename = "${path.module}/${local.infrastructure_id}/manifests/cluster-dns-02-config.yml"

  content = <<EOF
apiVersion: config.openshift.io/v1
kind: DNS
metadata:
  creationTimestamp: null
  name: cluster
spec:
  baseDomain: ${var.clustername}.${var.domain}
  privateZone:
    tags:
      Name: ${data.aws_route53_zone.ocp_private.name}
      kubernetes.io/cluster/${local.infrastructure_id}: owned
status: {}
EOF
}

# build the bootstrap ignition config
resource "null_resource" "generate_ignition_config" {
  depends_on = [
    "null_resource.manifest_cleanup_control_plane_machineset",
    "null_resource.manifest_cleanup_worker_machineset",
    "local_file.worker_machineset",
    "local_file.cluster_infrastructure_config",
    "local_file.cluster_dns_config",
  ]

  triggers = {
    install_config = "${data.template_file.install_config_yaml.rendered}"
    local_file_install_config = "${local_file.install_config.id}"
    local_file_infrastructure_config = "${local_file.cluster_infrastructure_config.id}"
    local_file_dns_config = "${local_file.cluster_dns_config.id}"
    local_file_worker_machineset = "${join(",", local_file.worker_machineset.*.id)}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/${local.infrastructure_id}"
  }

  provisioner "local-exec" {
    command = "rm -rf ${path.module}/${local.infrastructure_id}/_manifests ${path.module}/${local.infrastructure_id}/_openshift"
  }

  provisioner "local-exec" {
    command = "cp -r ${path.module}/${local.infrastructure_id}/manifests ${path.module}/${local.infrastructure_id}/_manifests"
  }

  provisioner "local-exec" {
    command = "cp -r ${path.module}/${local.infrastructure_id}/openshift ${path.module}/${local.infrastructure_id}/_openshift"
  }

  provisioner "local-exec" {
    command = "${path.module}/openshift-install --dir=${path.module}/${local.infrastructure_id} create ignition-configs"
  }
}

resource "null_resource" "cleanup" {
  depends_on = [
    "aws_instance.bootstrap",
    "aws_s3_bucket_object.bootstrap_ign"
  ]

  provisioner "local-exec" {
    when = "destroy"
    command = "rm -rf ${path.module}/${local.infrastructure_id}"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "rm -f ${path.module}/openshift-install"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "rm -f ${path.module}/oc"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "rm -f ${path.module}/kubectl"
  }
}

data "local_file" "bootstrap_ign" {
  depends_on = [
    "null_resource.generate_ignition_config"
  ]

  filename = "${path.module}/${local.infrastructure_id}/bootstrap.ign"
}

data "local_file" "master_ign" {
  depends_on = [
    "null_resource.generate_ignition_config"
  ]

  filename = "${path.module}/${local.infrastructure_id}/master.ign"
}

data "local_file" "worker_ign" {
  depends_on = [
    "null_resource.generate_ignition_config"
  ]

  filename = "${path.module}/${local.infrastructure_id}/worker.ign"
}

data "local_file" "cluster_infrastructure" {
  depends_on = [
    "null_resource.generate_manifests"
  ]

  filename = "${path.module}/${local.infrastructure_id}/manifests/cluster-infrastructure-02-config.yml"
}

resource "null_resource" "get_auth_config" {
  depends_on = [ "null_resource.generate_ignition_config" ]
  provisioner "local-exec" {
     when = "create"
     command = "cp ${path.module}/${local.infrastructure_id}/auth/* ${path.root}/ "
  }
  provisioner "local-exec" {
     when = "destroy"
     command = "rm ${path.root}/kubeconfig ${path.root}/kubeadmin-password "
  }
}
