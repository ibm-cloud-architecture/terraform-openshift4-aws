
output "clustername" {
    value = "${var.clustername}"
}

output "infrastructure_id" {
    value = "${local.infrastructure_id}"
}

output "public_vpc_id" {
    value = "${var.public_vpc_id}"
}


output "public_vpc_private_subnet_ids" {
  value = "${var.public_vpc_private_subnet_ids}"
}

output "public_vpc_public_subnet_ids" {
  value = "${public_vpc_public_subnet_ids}" 
}
