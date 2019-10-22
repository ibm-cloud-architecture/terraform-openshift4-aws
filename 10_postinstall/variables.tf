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

variable "openshift_installer_url" {
  default = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest"
}

variable "infrastructure_id" {
  default = ""
}

variable "clustername" { default = "ocp4" }

variable "domain" {
    default = "example.com"
}

variable "bootstrap_ip" {
}

variable "private_key_pem" {

}
