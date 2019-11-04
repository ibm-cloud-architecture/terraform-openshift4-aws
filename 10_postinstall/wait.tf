locals {
  infrastructure_id = "${var.infrastructure_id}"
}

resource "null_resource" "postinstall" {
  provisioner "local-exec" {
    command = "${path.module}/postinstall.sh ${local.infrastructure_id} ${var.clustername} ${var.domain}"
  }
}
