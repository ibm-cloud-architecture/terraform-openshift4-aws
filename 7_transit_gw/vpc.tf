data "aws_vpc" "ocp_private_vpc" {
  id = "${var.private_vpc_id}"
}

data "aws_vpc" "ocp_public_vpc" {
  id = "${var.public_vpc_id}"
}

data "aws_subnet" "pri_vpc_ocp_pri_subnet" {
  count       = "${length(var.private_vpc_private_subnet_ids)}"
  id          = "${element(var.private_vpc_private_subnet_ids, count.index)}"
}

data "aws_subnet" "pub_vpc_ocp_pri_subnet" {
  count       = "${length(var.public_vpc_private_subnet_ids)}"
  id          = "${element(var.public_vpc_private_subnet_ids, count.index)}"
}

data "aws_subnet" "pub_vpc_ocp_pub_subnet" {
  count       = "${length(var.public_vpc_public_subnet_ids)}"
  id          = "${element(var.public_vpc_public_subnet_ids, count.index)}"
}

data "aws_route_table" "pri_vpc_ocp_pri_route_table" {
  count       = "${length(var.private_vpc_private_subnet_ids)}"
  subnet_id = "${element(data.aws_subnet.pri_vpc_ocp_pri_subnet.*.id, count.index)}"
}

data "aws_route_table" "pub_vpc_ocp_pri_route_table" {
  count       = "${length(var.public_vpc_private_subnet_ids)}"
  subnet_id = "${element(data.aws_subnet.pub_vpc_ocp_pri_subnet.*.id, count.index)}"
}

data "aws_route_table" "pub_vpc_ocp_pub_route_table" {
  count       = "${length(var.public_vpc_public_subnet_ids)}"
  subnet_id = "${element(data.aws_subnet.pub_vpc_ocp_pub_subnet.*.id, count.index)}"
}