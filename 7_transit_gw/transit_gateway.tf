resource "aws_ec2_transit_gateway" "ocp_tgw" {
  tags = "${merge(
    var.default_tags, 
    map(
      "Name", "${local.infrastructure_id}-tgw",
    )
  )}"
   
}

data "aws_ec2_transit_gateway_route_table" "ocp_tgw_tbl" {
  id = "${aws_ec2_transit_gateway.ocp_tgw.association_default_route_table_id}"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "ocp_tgw_pri" {
  vpc_id = "${data.aws_vpc.ocp_private_vpc.id}"
  subnet_ids = "${data.aws_subnet.pri_vpc_ocp_pri_subnet.*.id}"
  transit_gateway_id = "${aws_ec2_transit_gateway.ocp_tgw.id}"

  tags = "${merge(
    var.default_tags, 
    map(
      "Name", "${local.infrastructure_id}-tgw-pri",
    )
  )}"
 
}

resource "aws_ec2_transit_gateway_vpc_attachment" "ocp_tgw_pub" {
  vpc_id = "${data.aws_vpc.ocp_public_vpc.id}"
  subnet_ids = "${data.aws_subnet.pub_vpc_ocp_pri_subnet.*.id}"
  transit_gateway_id = "${aws_ec2_transit_gateway.ocp_tgw.id}"

  tags = "${merge(
    var.default_tags, 
    map(
      "Name", "${local.infrastructure_id}-tgw-pub",
    )
  )}"
}

resource "aws_ec2_transit_gateway_route" "tgw_internet_route" {
    destination_cidr_block          = "0.0.0.0/0"
    transit_gateway_route_table_id  = "${data.aws_ec2_transit_gateway_route_table.ocp_tgw_tbl.id}"
    transit_gateway_attachment_id   = "${aws_ec2_transit_gateway_vpc_attachment.ocp_tgw_pub.id}"
}

resource "aws_route" "private_vpc_internet_route" {
    count                   = "${length(var.private_vpc_private_subnet_ids)}"
    destination_cidr_block  = "0.0.0.0/0"
    route_table_id          = "${element(data.aws_route_table.pri_vpc_ocp_pri_route_table.*.id, count.index)}"
    transit_gateway_id      = "${aws_ec2_transit_gateway.ocp_tgw.id}"
}

resource "aws_route" "pub_subnet_private_vpc_route" {
    count                   = "${length(var.public_vpc_public_subnet_ids)}"
    destination_cidr_block  = "${data.aws_vpc.ocp_private_vpc.cidr_block}"
    route_table_id          = "${element(data.aws_route_table.pub_vpc_ocp_pub_route_table.*.id, count.index)}"
    transit_gateway_id      = "${aws_ec2_transit_gateway.ocp_tgw.id}"
}

resource "aws_route" "pri_subnet_private_vpc_route" {
    count                   = "${length(var.public_vpc_private_subnet_ids)}"
    destination_cidr_block  = "${data.aws_vpc.ocp_private_vpc.cidr_block}"
    route_table_id          = "${element(data.aws_route_table.pub_vpc_ocp_pri_route_table.*.id, count.index)}"
    transit_gateway_id      = "${aws_ec2_transit_gateway.ocp_tgw.id}"
}