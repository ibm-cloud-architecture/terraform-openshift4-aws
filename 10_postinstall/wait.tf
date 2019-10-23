locals {
  infrastructure_id = "${var.infrastructure_id}"
  key = "${file("${var.private_key_file}")}"
}

resource "local_file" "ssh_key" {
    content     = "${var.private_key}"
    filename = "${path.module}/${var.private_key_file}"
}

# Wait for bootstrap complete
resource "null_resource" "wait_bootstrap" {
  depends_on = [ "local_file.ssh_key" ]

  provisioner "local-exec" {
    command = "sleep 600;while [ $bootdone -eq 0 ];do bootdone=$(ssh -i private_key -q core@10.10.10.253 [[ -f /opt/openshift/.bootkube.done ]] && echo "1" || echo "0");sleep 6;echo -n ".";done"
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
    private_key = "${local.key}"
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
    command = "scp -i ${var.private_key_file} -q core@${var.bootstrap_ip}:/home/core/mc.tar mc.tar"
  }

  provisioner "local-exec" {
    command = "tar -xvf mc.tar"
  }
}

resource "null_resource" "postinstall" {
  depends_on = [
    "null_resource.copy_yaml_bootstrap"
  ]

  provisioner "local-exec" {
    command = "postinstall.sh"
  }
}
