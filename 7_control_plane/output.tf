output "int_lb_url" {
    value = "${data.aws_lb.ocp_control_plane_int.dns_name}"
}

output "clustername" {
    value = "${var.clustername}"
}

output "infrastructure_id" {
    value = "${local.infrastructure_id}"
}

