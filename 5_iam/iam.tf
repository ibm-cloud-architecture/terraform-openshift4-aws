resource "aws_iam_role" "ocp_ec2_master_role" {
  name = "${local.infrastructure_id}-master-role"

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

# machine api and volume provisioning requires ec2*, load balancer service requires elb*,
# machine api requires iam passrole*, registry and bootstrap requires s3*
resource "aws_iam_role_policy" "ocp_ec2_master_role_policy" {
  name = "${local.infrastructure_id}-master-role-policy"
  role = "${aws_iam_role.ocp_ec2_master_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "iam:PassRole",
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

resource "aws_iam_instance_profile" "ocp_ec2_master_instance_profile" {
  name = "${local.infrastructure_id}-master-profile"
  role = "${aws_iam_role.ocp_ec2_master_role.name}"
}

resource "aws_iam_role" "ocp_ec2_worker_role" {
  name = "${local.infrastructure_id}-worker-role"

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

resource "aws_iam_role_policy" "ocp_ec2_worker_role_policy" {
  name = "${local.infrastructure_id}-worker-role-policy"
  role = "${aws_iam_role.ocp_ec2_worker_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*"
            ],
            "Resource": "*"
        } 
    ]
}
EOF
}


resource "aws_iam_instance_profile" "ocp_ec2_worker_instance_profile" {
  name = "${local.infrastructure_id}-worker-profile"
  role = "${aws_iam_role.ocp_ec2_worker_role.name}"
}