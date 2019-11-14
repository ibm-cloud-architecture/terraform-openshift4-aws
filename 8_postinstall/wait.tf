resource "null_resource" "postinstall" {
  provisioner "local-exec" {
    command = "${path.module}/postinstall.sh ${var.infrastructure_id} ${var.clustername} ${var.domain}"
  }
}
