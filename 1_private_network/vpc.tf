# create a vpc
resource "aws_vpc" "ocp_vpc" {
  cidr_block = "${ var.vpc_cidr }"

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.infrastructure_id}-pri",
      "kubernetes.io/cluster/${local.infrastructure_id}", "shared"
    )
  )}"
}
