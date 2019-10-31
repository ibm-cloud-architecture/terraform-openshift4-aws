output "infrastructure_id" {
    value = "${local.infrastructure_id}"
}

output "clustername" {
    value = "${var.clustername}"
}

output "private_vpc_id" {
    value = "${aws_vpc.ocp_vpc.id}"
}

output "private_vpc_private_subnet_ids" {
    value = "${aws_subnet.ocp_pri_subnet.*.id}"
}

output "private_vpc_public_subnet_ids" {
    value = "${aws_subnet.ocp_pub_subnet.*.id}"
}
