resource "aws_security_group" "private_ec2_api" {
  name =  "${var.cluster_id}-ec2-api"
  vpc_id =  data.aws_vpc.cluster_vpc.id

  tags =  merge(
    var.tags,
    map(
      "Name",  "${var.cluster_id}-private-ec2-api",
    )
  )
}

# allow anybody in the VPC to talk to ec2 through the private endpoint
resource "aws_security_group_rule" "private_ec2_ingress" {
  type        = "ingress"

  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = [
     var.cidr_block
  ]

  security_group_id =  aws_security_group.private_ec2_api.id
}

resource "aws_security_group_rule" "private_ec2_api_egress" {
  type        = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  security_group_id =  aws_security_group.private_ec2_api.id
}

resource "aws_security_group" "private_ecr_api" {
  count = var.airgapped.enabled ? 1 : 0
  name =  "${var.cluster_id}-ecr-api"
  vpc_id =  data.aws_vpc.cluster_vpc.id

  tags =  merge(
    var.tags,
    map(
      "Name",  "${var.cluster_id}-private-ecr-api",
    )
  )
}

# allow anybody in the VPC to talk to ecr through the private endpoint
resource "aws_security_group_rule" "private_ecr_ingress" {
  count = var.airgapped.enabled ? 1 : 0
  type        = "ingress"

  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = [
     var.cidr_block
  ]

  security_group_id =  aws_security_group.private_ecr_api[0].id
}

resource "aws_security_group_rule" "private_ecr_api_egress" {
  count = var.airgapped.enabled ? 1 : 0
  type        = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  security_group_id =  aws_security_group.private_ecr_api[0].id
}

resource "aws_security_group" "private_elb_api" {
  count = var.airgapped.enabled ? 1 : 0
  name =  "${var.cluster_id}-elb-api"
  vpc_id =  data.aws_vpc.cluster_vpc.id

  tags =  merge(
    var.tags,
    map(
      "Name",  "${var.cluster_id}-private-elb-api",
    )
  )
}

# allow anybody in the VPC to talk to ecr through the private endpoint
resource "aws_security_group_rule" "private_elb_ingress" {
  count = var.airgapped.enabled ? 1 : 0
  type        = "ingress"

  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = [
     var.cidr_block
  ]

  security_group_id =  aws_security_group.private_elb_api[0].id
}

resource "aws_security_group_rule" "private_elb_api_egress" {
  count = var.airgapped.enabled ? 1 : 0
  type        = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  security_group_id =  aws_security_group.private_elb_api[0].id
}
