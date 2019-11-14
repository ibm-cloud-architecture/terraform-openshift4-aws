data "aws_lb_target_group" "ocp_control_plane_int_6443" {
    arn = "${var.ocp_control_plane_lb_int_6443_tg_arn}"
}

data "aws_lb_target_group" "ocp_control_plane_int_22623" {
    arn = "${var.ocp_control_plane_lb_int_22623_tg_arn}"
}

data "aws_lb" "ocp_control_plane_int" {
    arn = "${var.ocp_control_plane_lb_int_arn}"
}

resource "aws_lb_target_group_attachment" "ocp_master_control_plane_int_6443" {
    count         = "${lookup(var.control_plane, "count", 3)}"
    target_group_arn = "${data.aws_lb_target_group.ocp_control_plane_int_6443.arn}"
    target_id = "${element(aws_instance.master.*.private_ip, count.index)}"
}

resource "aws_lb_target_group_attachment" "ocp_master_control_plane_int_22623" {
    count         = "${lookup(var.control_plane, "count", 3)}"
    target_group_arn = "${data.aws_lb_target_group.ocp_control_plane_int_22623.arn}"
    target_id = "${element(aws_instance.master.*.private_ip, count.index)}"
}

