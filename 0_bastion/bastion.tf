data "aws_ami" "bastion" {
    most_recent = true

    owners = ["531415883065"]

    filter {
        name = "image-id"
        values = ["${var.bastion_ami}"]
    }

}

resource "aws_iam_role" "ocp_ec2_bastion_role" {
   name = "${local.infrastructure_id}-bastion-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ocp_ec2_bastion_role_policy" {
  name = "${local.infrastructure_id}-bastion-role-policy"
  role = "${aws_iam_role.ocp_ec2_bastion_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "s3:GetObject"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ocp_ec2_bastion_instance_profile" {
  name = "${local.infrastructure_id}-bastion-profile"
  role = "${aws_iam_role.ocp_ec2_bastion_role.name}"
}  

resource "aws_security_group" "bastion" {
  name = "${local.infrastructure_id}-bastion"
  vpc_id = "${data.aws_vpc.ocp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.infrastructure_id}-bastion",
      "kubernetes.io/cluster/${local.infrastructure_id}", "shared"
    )
  )}"
}

# TODO do we need SSH?
resource "aws_security_group_rule" "bastion_ssh" {
  type        = "ingress"

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  
  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.bastion.id}"
  instance_type = "t2.micro"
  subnet_id     = "${data.aws_subnet.ocp_pub_subnet.0.id}"
  iam_instance_profile = "${aws_iam_instance_profile.ocp_ec2_bastion_instance_profile.name}"

  vpc_security_group_ids = "${concat(
    aws_security_group.bastion.*.id,
    list(data.aws_security_group.master.id)
  )}"

  availability_zone = "${element(data.aws_availability_zone.aws_azs.*.name, 0)}"

  tags = "${merge(
      var.default_tags,
      map("Name",  "${format("${local.infrastructure_id}-bastion")}")
  )}"
}
