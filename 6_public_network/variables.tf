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
variable "ocp_route53_private_zone_id" { default = "" }
variable "infrastructure_id" { default = "" }
variable "clustername" { default = "ocp4" }
variable "public_vpc_id" { default = "vpc-0ea3d8e587d46b10a" }

# Subnet Details
variable "public_vpc_private_subnet_cidrs" {
  type        = "list"
  default     = [ "172.16.10.0/24" ,"172.16.11.0/24", "172.16.12.0/24" ]
}

variable "public_vpc_public_subnet_cidrs" {
  type        = "list"
  default     = [ "172.16.20.0/24", "172.16.21.0/24", "172.16.22.0/24" ]
}

variable "domain" {
}
