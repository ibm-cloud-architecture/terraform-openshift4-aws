resource "null_resource" "postinstall" {
  count = var.airgapped ? 0 : 1
  provisioner "local-exec" {
    when = create
    command = "${path.module}/postinstall.sh ${var.infrastructure_id} ${var.clustername} ${var.domain}"
  }
}
