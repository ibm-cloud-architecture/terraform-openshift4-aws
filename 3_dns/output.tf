output "ocp_route53_private_zone_id" {
    value = "${aws_route53_zone.ocp_private.zone_id}"
}

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
    value = "${data.aws_lb.ocp_control_plane_int.arn}"
}