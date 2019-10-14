# Create private subnet in each AZ for the worker nodes to reside in
resource "aws_subnet" "ocp_pri_subnet" {
  count                   = "${length(var.aws_azs)}"

  vpc_id                  = "${aws_vpc.ocp_vpc.id}"
  cidr_block              = "${element(var.vpc_private_subnet_cidrs, count.index)}"
  availability_zone       = "${format("%s%s", element(list(var.aws_region), count.index), element(var.aws_azs, count.index))}"
  
  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("${local.infrastructure_id}-pri-%s-pri", format("%s%s", element(list(var.aws_region), count.index), element(var.aws_azs, count.index))) }",
      "kubernetes.io/cluster/${local.infrastructure_id}", "shared"
    )
  )}"
}



resource "aws_route_table" "ocp_pri_net_route_table" {
  count = "${length(var.aws_azs)}"

  vpc_id = "${aws_vpc.ocp_vpc.id}"

  tags = "${merge(
    var.default_tags, 
    map(
      "Name", "${format("${local.infrastructure_id}-pri-%s-rtbl", format("%s%s", element(list(var.aws_region), count.index), element(var.aws_azs, count.index)) )}",
      "kubernetes.io/cluster/${local.infrastructure_id}", "shared")
  )}"
}

resource "aws_route_table_association" "ocp_pri_net_route_table_assoc" {
  count          = "${length(var.aws_azs)}"

  subnet_id      = "${element(aws_subnet.ocp_pri_subnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.ocp_pri_net_route_table.*.id, count.index)}"
}

# private S3 endpoint
data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
}

resource "aws_vpc_endpoint" "private_s3" {
  vpc_id       = "${aws_vpc.ocp_vpc.id}"
  service_name = "${data.aws_vpc_endpoint_service.s3.service_name}"

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Principal": "*",
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}  
EOF

  tags = "${merge(
    var.default_tags, 
    map(
      "Name", "${format("${local.infrastructure_id}-pri-s3-vpce")}",
      "kubernetes.io/cluster/${local.infrastructure_id}", "shared")
  )}"

}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count = "${length(var.aws_azs)}"

  vpc_endpoint_id = "${aws_vpc_endpoint.private_s3.id}"
  route_table_id  = "${element(aws_route_table.ocp_pri_net_route_table.*.id, count.index)}"
}

## private ec2 endpoint
data "aws_vpc_endpoint_service" "ec2" {
  service = "ec2"
}

resource "aws_vpc_endpoint" "private_ec2" {
  vpc_id       = "${aws_vpc.ocp_vpc.id}"
  service_name = "${data.aws_vpc_endpoint_service.ec2.service_name}"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = [
    "${aws_security_group.private_ec2_api.id}"
  ]

  subnet_ids = "${aws_subnet.ocp_pri_subnet.*.id}"
  tags = "${merge(
    var.default_tags, 
    map(
      "Name", "${format("${local.infrastructure_id}-ec2-vpce")}"
    )
  )}"

}


