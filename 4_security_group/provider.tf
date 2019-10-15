provider "aws" {
  region = "${var.aws_region}"
}

data "aws_caller_identity" "current" {
}

resource "random_id" "clusterid" {
  byte_length = "2"
}

locals {
  infrastructure_id = "${var.infrastructure_id != "" ? "${var.infrastructure_id}" : "${var.clustername}-${random_id.clusterid.hex}"}"
}