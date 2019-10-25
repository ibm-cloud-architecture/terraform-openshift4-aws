
output "clustername" {
    value = "${var.clustername}"
}

output "infrastructure_id" {
    value = "${local.infrastructure_id}"
}

output "public_vpc_id" {
    value = "${aws_vpc.ocp_public_vpc.id}"
}

output "public_vpc_public_subnet_ids" {
    value = "${aws_subnet.ocp_pub_subnet.*.id}"
}

output "public_vpc_private_subnet_ids" {
    value = "${aws_subnet.ocp_pri_subnet.*.id}"
}