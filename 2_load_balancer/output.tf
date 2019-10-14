output "private_vpc_id" {
    value = "${data.aws_vpc.ocp_vpc.id}"
}

output "infrastructure_id" {
    value = "${local.infrastructure_id}"
}

output "clustername" {
    value = "${var.clustername}"
}

output "ocp_control_plane_lb_int_arn" {
    value = "${aws_lb.ocp_control_plane_int.arn}"
}

output "ocp_control_plane_lb_int_6443_tg_arn" {
    value = "${aws_lb_target_group.ocp_control_plane_int_6443.arn}"
}

output "ocp_control_plane_lb_int_22623_tg_arn" {
    value = "${aws_lb_target_group.ocp_control_plane_int_22623.arn}"
}