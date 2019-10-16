resource "aws_iam_role" "ocp_ec2_bootstrap_role" {
   name = "${local.infrastructure_id}-bootstrap-role"

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

resource "aws_iam_role_policy" "ocp_ec2_bootstrap_role_policy" {
  name = "${local.infrastructure_id}-bootstrap-role-policy"
  role = "${aws_iam_role.ocp_ec2_bootstrap_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
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

resource "aws_iam_instance_profile" "ocp_ec2_bootstrap_instance_profile" {
  name = "${local.infrastructure_id}-bootstrap-profile"
  role = "${aws_iam_role.ocp_ec2_bootstrap_role.name}"
}  

data "aws_iam_instance_profile" "ocp_ec2_master_instance_profile" {
  name = "${var.ocp_master_instance_profile_id}"
}

data "aws_iam_instance_profile" "ocp_ec2_worker_instance_profile" {
  name = "${var.ocp_worker_instance_profile_id}"
}