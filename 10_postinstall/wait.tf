
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

# Wait for bootstrap complete
resource "null_resource" "wait_bootstrap" {
  depends_on = [
    "null_resource.openshift_installer",
    "null_resource.openshift_client"
  ]

  provisioner "local-exec" {
     command = "cp -r ../8_bootstrap/${local.infrastructure_id} ${path.module}/${local.infrastructure_id}/"
  }

  provisioner "local-exec" {
    command = "${path.module}/openshift-install --dir=${path.module}/${local.infrastructure_id} wait-for install-complete"
  }
}

resource "null_resource" "copy_mcs_bootstrap" {
  depends_on = [
    "null_resource.wait_bootstrap"
  ]

  connection {
    type = "ssh"
    user = "core"
    host = "${var.bootstrap_ip}"
    private_key = "${var.private_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [ "sudo cp /etc/mcs/bootstrap/machine-configs/rendered-master* /opt/openshift/openshift",
    "sudo tar -cvf /home/core/mc.tar /opt/openshift/openshift /opt/openshift/manifests" ]
  }

}

resource "null_resource" "copy_yaml_bootstrap" {
  depends_on = [
    "null_resource.copy_mcs_bootstrap"
  ]

  provisioner "local-exec" {
    command = "scp -i ${var.private_key_pem} -q core@${var.bootstrap_ip}:/home/core/mc.tar mc.tar"
  }

  provisioner "local-exec" {
    command = "tar -xvf mc.tar"
  }
}

data "template_file" "oc_script" {
  template  = "${file("${path.module}/templates/postinstall.sh.tpl")}"
}

resource "null_resource" "postinstall" {
  depends_on = [
    "null_resource.copy_yaml_bootstrap"
  ]

  provisioner "local-exec" {
    command = ""
  }
}
