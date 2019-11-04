resource "null_resource" "postinstall" {
  depends_on = [ "module.control_plane.aws_instance.master" ]

  provisioner "local-exec" {
    command = "${path.module}/postinstall.sh ${var.infrastructure_id} ${var.clustername} ${var.domain}"
  }
}
