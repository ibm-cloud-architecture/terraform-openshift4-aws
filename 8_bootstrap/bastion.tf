data "aws_ami" "bastion" {
    most_recent = true

    owners = ["${var.ami_owner}"]
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

resource "aws_iam_role_policy" "ocp_ec2_iam_role_policy" {
  name = "${local.infrastructure_id}-iam-role-policy"
  role = "${aws_iam_role.ocp_ec2_bastion_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateDhcpOptions",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:ReplaceRouteTableAssociation",
                "ec2:DescribeInstances",
                "ec2:DeleteVpcEndpoints",
                "ec2:AttachInternetGateway",
                "iam:PutRolePolicy",
                "route53:ListHostedZonesByName",
                "iam:AddRoleToInstanceProfile",
                "ec2:DeleteRouteTable",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:CreateRoute",
                "ec2:CreateInternetGateway",
                "ec2:DescribeVolumes",
                "s3:PutObjectTagging",
                "ec2:DeleteInternetGateway",
                "iam:ListRolePolicies",
                "s3:DeleteObject",
                "ec2:DescribeKeyPairs",
                "iam:GetRole",
                "s3:GetBucketWebsite",
                "ec2:DescribeVpcClassicLinkDnsSupport",
                "ec2:CreateTags",
                "elasticloadbalancing:CreateTargetGroup",
                "ec2:ModifyNetworkInterfaceAttribute",
                "iam:DeleteRole",
                "ec2:RunInstances",
                "ec2:DisassociateRouteTable",
                "s3:GetReplicationConfiguration",
                "ec2:CreateVolume",
                "ec2:RevokeSecurityGroupIngress",
                "s3:PutObject",
                "elasticloadbalancing:AddTags",
                "ec2:DeleteDhcpOptions",
                "ec2:DeleteNatGateway",
                "ec2:CreateSubnet",
                "ec2:DescribeSubnets",
                "iam:GetRolePolicy",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "iam:CreateInstanceProfile",
                "s3:GetLifecycleConfiguration",
                "s3:GetBucketTagging",
                "tag:GetResources",
                "ec2:CreateNatGateway",
                "iam:TagRole",
                "ec2:DescribeRegions",
                "ec2:CreateVpc",
                "s3:ListBucket",
                "ec2:DescribeVpcEndpointServices",
                "ec2:DescribeVpcAttribute",
                "ec2:ModifySubnetAttribute",
                "iam:ListInstanceProfilesForRole",
                "iam:PassRole",
                "s3:PutBucketTagging",
                "ec2:DescribeAvailabilityZones",
                "iam:DeleteRolePolicy",
                "route53:DeleteHostedZone",
                "s3:DeleteBucket",
                "iam:DeleteInstanceProfile",
                "ec2:ReleaseAddress",
                "ec2:AssociateDhcpOptions",
                "elasticloadbalancing:CreateLoadBalancer",
                "route53:ListHostedZones",
                "iam:ListRoles",
                "s3:GetBucketVersioning",
                "elasticloadbalancing:DeleteTargetGroup",
                "route53:ListTagsForResource",
                "ec2:DescribeSecurityGroups",
                "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
                "ec2:DescribeVpcs",
                "s3:GetBucketCORS",
                "elasticloadbalancing:DescribeTargetGroups",
                "iam:GetUser",
                "route53:AssociateVPCWithHostedZone",
                "s3:GetObjectVersion",
                "elasticloadbalancing:DeleteListener",
                "ec2:DeleteSubnet",
                "elasticloadbalancing:RegisterTargets",
                "route53:GetHostedZone",
                "iam:RemoveRoleFromInstanceProfile",
                "s3:CreateBucket",
                "iam:CreateRole",
                "ec2:CopyImage",
                "ec2:AssociateRouteTable",
                "elasticloadbalancing:DeleteLoadBalancer",
                "ec2:DescribeInternetGateways",
                "s3:GetBucketObjectLockConfiguration",
                "elasticloadbalancing:DescribeLoadBalancers",
                "s3:GetObjectAcl",
                "ec2:DeleteVolume",
                "iam:SimulatePrincipalPolicy",
                "autoscaling:DescribeAutoScalingGroups",
                "route53:ListResourceRecordSets",
                "s3:PutBucketAcl",
                "ec2:DescribeAccountAttributes",
                "route53:UpdateHostedZoneComment",
                "elasticloadbalancing:DescribeInstanceHealth",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeRouteTables",
                "route53:CreateHostedZone",
                "route53:DisassociateVPCFromHostedZone",
                "ec2:CreateRouteTable",
                "ec2:DeleteNetworkInterface",
                "route53:ChangeResourceRecordSets",
                "elasticloadbalancing:DeregisterTargets",
                "ec2:DetachInternetGateway",
                "ec2:DescribePrefixLists",
                "ec2:DescribeInstanceCreditSpecifications",
                "ec2:DescribeVpcClassicLink",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "s3:GetObject",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "route53:ChangeTagsForResource",
                "ec2:DescribeVpcEndpoints",
                "ec2:DeleteVpc",
                "ec2:AssociateAddress",
                "ec2:DeregisterImage",
                "ec2:DescribeAddresses",
                "ec2:DeleteSnapshot",
                "route53:GetChange",
                "elasticloadbalancing:ConfigureHealthCheck",
                "ec2:DescribeInstanceAttribute",
                "s3:GetBucketLogging",
                "ec2:DescribeDhcpOptions",
                "s3:GetAccelerateConfiguration",
                "s3:PutEncryptionConfiguration",
                "s3:GetEncryptionConfiguration",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DescribeListeners",
                "ec2:DescribeNetworkInterfaces",
                "s3:GetBucketRequestPayment",
                "ec2:CreateSecurityGroup",
                "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
                "s3:GetObjectTagging",
                "ec2:ModifyVpcAttribute",
                "ec2:ModifyInstanceAttribute",
                "s3:PutObjectAcl",
                "ec2:AuthorizeSecurityGroupEgress",
                "elasticloadbalancing:AttachLoadBalancerToSubnets",
                "ec2:TerminateInstances",
                "iam:GetInstanceProfile",
                "elasticloadbalancing:DescribeTags",
                "ec2:DescribeTags",
                "ec2:DeleteRoute",
                "iam:ListUserPolicies",
                "ec2:DescribeNatGateways",
                "iam:ListInstanceProfiles",
                "elasticloadbalancing:CreateLoadBalancerListeners",
                "ec2:AllocateAddress",
                "ec2:DescribeImages",
                "ec2:CreateVpcEndpoint",
                "ec2:DeleteSecurityGroup",
                "elasticloadbalancing:DescribeTargetHealth",
                "iam:ListUsers",
                "s3:GetBucketLocation",
                "elasticloadbalancing:ModifyTargetGroup"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ocp_ec2_bastion_vpc_endpoint" {
  name = "${local.infrastructure_id}-bastion-vpc_endpoint"
  role = "${aws_iam_role.ocp_ec2_bastion_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:ModifyVpcEndpointServicePermissions",
                "ec2:ModifyVpcEndpointServiceConfiguration",
                "ec2:CreateVpcEndpointConnectionNotification",
                "ec2:AcceptVpcEndpointConnections",
                "ec2:DeleteVpcEndpoints",
                "route53:DisassociateVPCFromHostedZone",
                "ec2:DescribeVpcEndpointServices",
                "ec2:DescribeVpcEndpointServiceConfigurations",
                "ec2:DeleteVpcEndpointServiceConfigurations",
                "ec2:ModifyVpcEndpointConnectionNotification",
                "ec2:DescribeVpcEndpointConnectionNotifications",
                "ec2:CreateVpcEndpointServiceConfiguration",
                "ec2:DescribeVpcEndpointServicePermissions",
                "ec2:DeleteVpcEndpointConnectionNotifications",
                "ec2:CreateVpcEndpoint",
                "ec2:DescribeVpcEndpoints",
                "route53:AssociateVPCWithHostedZone",
                "ec2:DescribeVpcEndpointConnections",
                "ec2:RejectVpcEndpointConnections",
                "ec2:ModifyVpcEndpoint"
            ],
            "Resource": "*"
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
  vpc_id = "${aws_vpc.ocp_public_vpc.id}"

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

resource "aws_key_pair" "terraform_ec2_key" {
  key_name = "${local.infrastructure_id}-key"
  public_key = "${tls_private_key.installkey.pub"}"
}

resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.bastion.id}"
  instance_type = "t2.micro"
  subnet_id     = "${data.aws_subnet.ocp_pri_subnet.0.id}"
  iam_instance_profile = "${aws_iam_instance_profile.ocp_ec2_bastion_instance_profile.name}"
  associate_public_ip_address = "true"
  key_name = "${local.infrastructure_id}-key}"
  vpc_security_group_ids = "${aws_security_group.bastion.*.id}"
  root_block_device {
    volume_size = 100
  }

  availability_zone = "${element(data.aws_availability_zone.aws_azs.*.name, 0)}"

  tags = "${merge(
      var.default_tags,
      map("Name",  "${format("${local.infrastructure_id}-bastion")}")
  )}"

}

resource "null_resource" "install_oc" {
  depends_on = [ "aws_instance.bastion" ]
  connection {
    host          = "${aws_instance.bastion.public_ip}"
    user          = "ec2-user"
    private_key   =  "${tls_private_key.installkey.private_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install git -y",
      "mkdir ocp42",
      "chdir ocp42",
      "wget https://releases.hashicorp.com/terraform/0.12.12/terraform_0.12.12_linux_amd64.zip",
      "tar -xf terraform_0.12.12_linux_amd64.zip",
      "sudo mv terraform /usr/local/bin/terraform",
      "wget -r -l1 -np -nd ${var.openshift_installer_url} -A 'openshift-install-linux-4*.tar.gz'",
      "tar -xf openshift-install-linux-4*.tar.gz",
      "sudo mv oc /usr/local/bin/oc"
   ]
}

}
