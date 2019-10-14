resource "aws_lb" "ocp_control_plane_int" {
  name = "${local.infrastructure_id}-int"

  load_balancer_type = "network"
  internal = "true"
  subnets = "${data.aws_subnet.ocp_pri_subnet.*.id}"

  tags = "${var.default_tags}"
}

resource "aws_lb_listener" "ocp_control_plane_int_6443" {
  load_balancer_arn = "${aws_lb.ocp_control_plane_int.arn}"

  port = "6443"
  protocol = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.ocp_control_plane_int_6443.arn}"
    type = "forward"
  }
}

resource "aws_lb_listener" "ocp_control_plane_int_22623" {
  load_balancer_arn = "${aws_lb.ocp_control_plane_int.arn}"

  port = "22623"
  protocol = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.ocp_control_plane_int_22623.arn}"
    type = "forward"
  }
}

resource "aws_lb_target_group" "ocp_control_plane_int_6443" {
  name = "${local.infrastructure_id}-6443-int-tg"
  port = 6443
  protocol = "TCP"
  tags = "${var.default_tags}"
  target_type = "ip"
  vpc_id = "${data.aws_vpc.ocp_vpc.id}"
  deregistration_delay = 60
}

resource "aws_lb_target_group" "ocp_control_plane_int_22623" {
  name = "${local.infrastructure_id}-22623-int-tg"
  port = 22623
  protocol = "TCP"
  tags = "${var.default_tags}"
  target_type = "ip"
  vpc_id = "${data.aws_vpc.ocp_vpc.id}"
  deregistration_delay = 60
}


resource "aws_vpc_endpoint_service" "ocp_control_plane" {
  acceptance_required = false
  network_load_balancer_arns = ["${aws_lb.ocp_control_plane_int.arn}"]

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.infrastructure_id}-control-plane-vpce"
    )
  )}"

}
