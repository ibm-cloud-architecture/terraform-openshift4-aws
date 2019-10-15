data "aws_vpc" "ocp_vpc" {
  id = "${var.private_vpc_id}"
}


data "aws_lb" "ocp_control_plane_int" {
  arn = "${var.ocp_control_plane_lb_int_arn}"
}