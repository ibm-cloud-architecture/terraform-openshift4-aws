####### AWS Access and Region Details #############################
variable "aws_region" {
  default  = "us-east-2"
  description = "One of us-east-2, us-east-1, us-west-1, us-west-2, ap-south-1, ap-northeast-2, ap-southeast-1, ap-southeast-2, ap-northeast-1, us-west-2, eu-central-1, eu-west-1, eu-west-2, sa-east-1"
}

variable "aws_azs" {
  type  = "list"
  description = "The availability zone letter appendix you want to deploy to in the selected region "
  default = ["a", "b", "c"]
}

variable "default_tags" {
  default = {}
}

variable "infrastructure_id" { default = "" }
variable "clustername" { default = "ocp4" }
variable "vpc_cidr" { default = "172.31.0.0/16" }

# Subnet Details
variable "public_vpc_private_subnet_cidrs" {
  description = "List of subnet CIDRs"
  type        = "list"
  default     = ["172.31.0.0/24", "172.31.1.0/24", "172.31.2.0/24" ]
}

variable "public_vpc_public_subnet_cidrs" {
  description = "List of subnet CIDRs"
  type        = "list"
  default     = ["172.31.4.0/24", "172.31.5.0/24", "172.31.6.0/24" ]
}

variable "domain" {
}