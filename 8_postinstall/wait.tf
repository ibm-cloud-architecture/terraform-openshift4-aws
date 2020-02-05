resource "null_resource" "postinstall" {

  provisioner "local-exec" {
    when = create
    command = "${path.module}/postinstall.sh ${var.infrastructure_id} ${var.clustername} ${var.domain} ${var.airgapped}"
  }
  provisioner "local-exec" {
    when = destroy
    command = "${path.module}/worker_import.sh ${var.infrastructure_id} ${var.clustername} ${var.domain} ${var.airgapped}"
  }
}
