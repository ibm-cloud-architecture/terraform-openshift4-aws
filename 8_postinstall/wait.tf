resource "null_resource" "postinstall" {

  provisioner "local-exec" {
    when = create
    command = "${path.module}/postinstall.sh ${var.infrastructure_id} ${var.clustername} ${var.domain} ${var.airgapped}"
  }
}
