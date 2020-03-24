variable "infrastructure_id" {
  type        = string
  description = "The identifier for infra resources."
}

variable "clustername" {
  type        = string
  description = "The identifier for the cluster."
}

variable "domain" {
  type        = string
  description = "The DNS domain for the cluster."
}

variable "ami" {
  type        = string
  description = "The AMI ID for the RHCOS nodes"
}

variable "cluster_network_cidr" {
  type        = string
  default     = "192.168.0.0/17"
}

variable "service_network_cidr" {
  type        = string
  default     = "192.168.128.0/24"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "192.168.0.0/24"
}

variable "cluster_network_host_prefix" {
  type        = string
  default     = "23"
}

variable "aws_worker_instance_type" {
  type = string
  description = "Instance type for the worker node(s). Example: `m4.large`."
}

variable "aws_worker_root_volume_type" {
  type        = string
  description = "The type of volume for the root block device of worker nodes."
}

variable "aws_worker_root_volume_size" {
  type        = string
  description = "The size of the volume in gigabytes for the root block device of worker nodes."
}

variable "aws_worker_root_volume_iops" {
  type = string

  description = <<EOF
The amount of provisioned IOPS for the root block device of worker nodes.
Ignored if the volume type is not io1.
EOF

}


variable "master_count" {
  type        = number
  description = "The number of master nodes."
  default     = 3
}

variable "openshift_pull_secret" {
  type        = string
  default     = "./openshift_pull_secret.json"
}

variable "openshift_installer_url" {
  type        = string
  description = "The URL to download OpenShift installer."
  default     = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest"
}

variable "aws_access_key_id" {
  type        = string
  description = "AWS access key"
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS Secret"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "aws_worker_availability_zones" {
  type = list(string)
  description = "The availability zones to provision for workers.  Worker instances are created by the machine-API operator, but this variable controls their supporting infrastructure (subnets, routing, etc.)."
}

variable "dns_public_id" {
  type = string
  description = "public route53 id"
}

variable "airgapped" {
  type = map(string)
  default = {
    airgapped  = false
    repository = ""
  }
}
