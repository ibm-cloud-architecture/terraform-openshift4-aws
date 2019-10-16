# create a vpc
# In real world, we wouldn't create the VPC, customer will have the VPC
# And the terraform bastion host shold run in that VPC.
# So need to change this code to use existing VPC
# And we might also need to attach this public to the private Route53 zone as well, maybe
resource "aws_vpc" "ocp_public_vpc" {
  cidr_block = "${ var.vpc_cidr }"
  
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = "${merge(
    var.default_tags, 
    map(
      "Name", "${local.infrastructure_id}-pub",
    )
  )}"
}