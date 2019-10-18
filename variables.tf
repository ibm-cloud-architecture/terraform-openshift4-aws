variable "aws_region" { default = "" }
variable "aws_azs" { default = ["a", "b", "c"] }
variable "default_tags" { default = {} }
variable "infrastructure_id" { default = "" }
variable "clustername" { default = "ocp4" }
variable "private_vpc_cidr" { default = "10.10.0.0/16" }
variable "public_vpc_cidr" { default = "172.16.0.0/16" }
variable "vpc_private_subnet_cidrs" { default = "" }
variable "domain" { default = "" }
variable "public_vpc_private_subnet_cidrs" { default = "" }
variable "public_vpc_public_subnet_cidrs" { default = "" }
variable "ami" { default = "" }
variable "aws_access_key_id" { default = "" }
variable "aws_secret_access_key" { default = "" }
variable "cluster_network_cidr" { default = "192.168.0.0/17" }
variable "cluster_network_host_prefix" { default = "23" }
variable "service_network_cidr" { default = "192.168.128.0/24" }
variable "bootstrap" { default = {         type = "i3.xlarge"} }
variable "control_plane" { default = {         count = "3",         type = "m4.xlarge",         disk = "120"} }
variable "worker" { default = {         count = "3",         type = "m4.large",         disk = "120"} }
variable "openshift_pull_secret" { default = "./openshift_pull_secret.json" }
variable "use_worker_machinesets" { default = true }
variable "openshift_installer_url" { default = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest" }
