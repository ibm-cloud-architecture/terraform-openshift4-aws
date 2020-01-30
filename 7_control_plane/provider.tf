provider "aws" {
  region =  var.aws_region
}

data "aws_caller_identity" "current" {
}

resource "random_id" "clusterid" {
  byte_length = "2"
}

data "aws_region" "current" {}

data "aws_availability_zone" "aws_azs" {
  count =  length(var.aws_azs)
  name = "${format("%s%s", data.aws_region.current.name, element(var.aws_azs, count.index))}"
}

locals {
  infrastructure_id = "${var.infrastructure_id != "" ? "${var.infrastructure_id}" : "${var.clustername}-${random_id.clusterid.hex}"}"
}
