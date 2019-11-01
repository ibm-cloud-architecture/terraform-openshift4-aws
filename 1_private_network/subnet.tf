# Create private subnet in each AZ for the dmz
resource "aws_subnet" "ocp_pri_subnet" {
  count                   = "${length(var.aws_azs)}"

  vpc_id                  = "${aws_vpc.ocp_vpc.id}"
  cidr_block              = "${element(var.vpc_private_subnet_cidrs, count.index)}"
  availability_zone       = "${format("%s%s", element(list(var.aws_region), count.index), element(var.aws_azs, count.index))}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("${local.infrastructure_id}-pub-%s-pri", format("%s%s", element(list(var.aws_region), count.index), element(var.aws_azs, count.index))) }",
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
      "Name", "${format("${local.infrastructure_id}-pub-rtbl-%s-pri", format("%s%s", element(list(var.aws_region), count.index), element(var.aws_azs, count.index)))}",
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



resource "aws_subnet" "ocp_pub_subnet" {
  count                   = "${length(var.aws_azs)}"

  vpc_id                  = "${aws_vpc.ocp_vpc.id}"
  cidr_block              = "${element(var.vpc_public_subnet_cidrs, count.index)}"
  availability_zone       = "${format("%s%s", element(list(var.aws_region), count.index), element(var.aws_azs, count.index))}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("${local.infrastructure_id}-pub-%s-pub", format("%s%s", element(list(var.aws_region), count.index), element(var.aws_azs, count.index))) }",
      "kubernetes.io/cluster/${local.infrastructure_id}", "shared",
      "kubernetes.io/role/elb", "1",
      "KubernetesCluster", "${local.infrastructure_id}"
    )
  )}"
}

resource "aws_internet_gateway" "ocp_igw" {
  vpc_id = "${aws_vpc.ocp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.infrastructure_id}-pub-igw"
    )
  )}"
}

resource "aws_route" "ocp_pub_net_route" {
  count = "${length(var.aws_azs)}"

  route_table_id = "${element(aws_route_table.ocp_pub_net_route_table.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.ocp_igw.id}"
}

resource "aws_route_table" "ocp_pub_net_route_table" {
  count          = "${length(var.aws_azs)}"

  vpc_id = "${aws_vpc.ocp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("${local.infrastructure_id}-pub-rtbl-%s-pub", format("%s%s", element(list(var.aws_region), count.index), element(var.aws_azs, count.index)))}"
    )
  )}"

}

resource "aws_route_table_association" "ocp_pub_net_route_table_assoc" {
  count          = "${length(var.aws_azs)}"

  subnet_id      = "${element(aws_subnet.ocp_pub_subnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.ocp_pub_net_route_table.*.id, count.index)}"
}

# Create Elastic IP for NAT gateway in each AZ
resource "aws_eip" "ocp_ngw_eip" {
  count = "${length(var.aws_azs)}"
  vpc   = "true"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("${local.infrastructure_id}-pub-ngw-eip-%1d", count.index + 1)}"
    )
  )}"
}

# Create NAT gateways for the private networks in each AZ
resource "aws_nat_gateway" "ocp_ngw" {
  count                   = "${length(var.aws_azs)}"

  depends_on = [
    "aws_internet_gateway.ocp_igw"
  ]

  allocation_id           = "${element(aws_eip.ocp_ngw_eip.*.id, count.index)}"
  subnet_id               = "${element(aws_subnet.ocp_pub_subnet.*.id, count.index)}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${format("${local.infrastructure_id}-pub-ngw-%1d", count.index + 1)}"
    )
  )}"
}

resource "aws_route" "ocp_pri_net_route_ngw" {
  count = "${length(var.aws_azs)}"

  route_table_id = "${element(aws_route_table.ocp_pri_net_route_table.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"

  # TODO if no nat gateway exists, you may use a transit gateway or peering connection here
  nat_gateway_id = "${element(aws_nat_gateway.ocp_ngw.*.id, count.index)}"
}
