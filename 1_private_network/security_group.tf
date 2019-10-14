resource "aws_security_group" "private_ec2_api" {
  name = "${local.infrastructure_id}-ec2-api"
  vpc_id = "${aws_vpc.ocp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.infrastructure_id}-private-ec2-api",
    )
  )}"
}

# allow anybody in the VPC to talk to ec2 through the private endpoint
resource "aws_security_group_rule" "private_ec2_ingress" {
  type        = "ingress"

  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = [
    "${var.vpc_cidr}"
  ]

  security_group_id = "${aws_security_group.private_ec2_api.id}"
}

resource "aws_security_group_rule" "private_ec2_api_egress" {
  type        = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  
  security_group_id = "${aws_security_group.private_ec2_api.id}"
}