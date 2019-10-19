
output "clustername" {
    value = "${var.clustername}"
}

output "infrastructure_id" {
    value = "${local.infrastructure_id}"
}

output "public_vpc_id" {
    value = "vpc-0ea3d8e587d46b10a"
}


output "public_vpc_private_subnet_ids" {
  value = [
  "subnet-0556e9da906c48b09",
  "subnet-03eb22e1bb944d5a0",
  "subnet-014e8063787f5bd0c",
]
}

output "public_vpc_public_subnet_ids" {
  value = [
  "subnet-0e0eea1735086ae90",
  "subnet-086c2117dde507c69",
  "subnet-02a76d7dbb84a5070",
]
}

