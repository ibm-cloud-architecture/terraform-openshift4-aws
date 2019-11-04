data "aws_security_group" "master" {
    id = "${var.ocp_control_plane_security_group_id}"
}

data "aws_security_group" "worker" {
    id = "${var.ocp_worker_security_group_id}"
}

resource "aws_security_group" "bootstrap" {
  name = "${local.infrastructure_id}-bootstrap"
  vpc_id = "${data.aws_vpc.ocp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.infrastructure_id}-bootstrap",
      "kubernetes.io/cluster/${local.infrastructure_id}", "shared"
    )
  )}"
}

# TODO do we need SSH?
resource "aws_security_group_rule" "bootstrap_ssh" {
  type        = "ingress"

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  
  security_group_id = "${aws_security_group.bootstrap.id}"
}

# TODO huh?
resource "aws_security_group_rule" "bootstrap_19531" {
  type        = "ingress"

  from_port   = 19531
  to_port     = 19531
  protocol    = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  
  security_group_id = "${aws_security_group.bootstrap.id}"
}
