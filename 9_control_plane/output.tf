output "int_lb_url" {
    value = "${data.aws_lb.ocp_control_plane_int.dns_name}"
}