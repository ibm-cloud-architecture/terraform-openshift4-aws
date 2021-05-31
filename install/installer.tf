#locals {
#  infrastructure_id = "${var.infrastructure_id != "" ? "${var.infrastructure_id}" : "${var.clustername}-${random_id.clusterid.hex}"}"
#  infrastructure_id = 
#}

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

data "local_file" "cabundle" {
  count = var.airgapped["enabled"] ? 1 : 0
  filename = "${var.airgapped.cabundle}"
}


data "template_file" "install_config_yaml" {
  template = <<-EOF
apiVersion: v1
baseDomain: ${var.domain}
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 3
  platform:
    aws:
      rootVolume:
        iops: ${var.aws_worker_root_volume_iops}
        size: ${var.aws_worker_root_volume_size}
        type: ${var.aws_worker_root_volume_type}
      type: ${var.aws_worker_instance_type}
      zones:
      %{ for zone in var.aws_worker_availability_zones}
      - ${zone}%{ endfor }
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
additionalTrustBundle: | 
  ${indent(2,data.local_file.cabundle[0].content)}
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

# build the bootstrap ignition config
resource "null_resource" "generate_ignition_config" {
  depends_on = [
    null_resource.manifest_cleanup_control_plane_machineset,
    local_file.airgapped_registry_upgrades,
  ]

  triggers = {
    install_config                   =  data.template_file.install_config_yaml.rendered
    local_file_install_config        =  local_file.install_config.id
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

resource "null_resource" "extractInfrastructureID" {
  depends_on = [
    null_resource.generate_manifests
  ]

  provisioner "local-exec" {
    when    = create
    command = "cat ${path.module}/temp/.openshift_install_state.json | jq -r '.\"*installconfig.ClusterID\".InfraID' | tr -d '\n' > ${path.module}/infraID"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${path.module}/infraID"
  }
}


data "local_file" "infrastructureID" {
  depends_on = [
    null_resource.extractInfrastructureID
  ]
  filename        =  "${path.module}/infraID"

}

resource "null_resource" "delete_aws_resources" {
  depends_on = [
    null_resource.cleanup
  ]

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/aws_cleanup.sh"
  }

}

resource "null_resource" "cleanup" {
  depends_on = [
    null_resource.generate_ignition_config
  ]

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
