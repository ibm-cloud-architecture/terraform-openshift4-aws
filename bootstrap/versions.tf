terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    ignition = {
      source = "terraform-providers/ignition"
    }
  }
  required_version = ">= 0.13"
}
