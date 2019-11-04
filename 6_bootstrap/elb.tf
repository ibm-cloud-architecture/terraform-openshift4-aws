data "aws_lb_target_group" "ocp_control_plane_int_6443" {
    arn = "${var.ocp_control_plane_lb_int_6443_tg_arn}"
}

data "aws_lb_target_group" "ocp_control_plane_int_22623" {
    arn = "${var.ocp_control_plane_lb_int_22623_tg_arn}"
}

data "aws_lb" "ocp_control_plane_int" {
    arn = "${var.ocp_control_plane_lb_int_arn}"
}

resource "aws_lb_target_group_attachment" "ocp_bootstrap_control_plane_int_6443" {
  target_group_arn = "${data.aws_lb_target_group.ocp_control_plane_int_6443.arn}"
  target_id = "${aws_instance.bootstrap.private_ip}"
}

resource "aws_lb_target_group_attachment" "ocp_bootstrap_control_plane_int_22623" {
  target_group_arn = "${data.aws_lb_target_group.ocp_control_plane_int_22623.arn}"
  target_id = "${aws_instance.bootstrap.private_ip}"
}