variable "aws_config_version" {
  description = <<EOF
(internal) This declares the version of the AWS configuration variables.
It has no impact on generated assets but declares the version contract of the configuration.
EOF

  default = "1.0"
}

variable "aws_bootstrap_instance_type" {
  type = string
  description = "Instance type for the bootstrap node. Default: `i3.xlarge`."
  default = "i3.xlarge"
}

variable "aws_master_instance_type" {
  type = string
  description = "Instance type for the master node(s). Default: `m4.xlarge`."
  default = "m4.xlarge"
}

variable "aws_worker_instance_type" {
  type = string
  description = "Instance type for the worker node(s). Default: `m4.2xlarge`."
  default = "m4.2xlarge"
}

variable "aws_ami" {
  type = string
  description = <<EOF
AMI for all nodes.  An encrypted copy of this AMI will be used.
The list of RedHat CoreOS AMI for each of the AWS region can be found in:
`https://github.com/openshift/installer/blob/master/data/data/rhcos-amd64.json`
Get the History of the file to find an older AMI list
EOF
}

variable "aws_extra_tags" {
  type = map(string)

  description = <<EOF
(optional) Extra AWS tags to be applied to created resources.

Example: `{ "owner" = "me", "kubernetes.io/cluster/mycluster" = "owned" }`
EOF

  default = {}
}

variable "aws_master_root_volume_type" {
  type        = string
  description = "The type of volume for the root block device of master nodes."
  default = "gp2"
}

variable "aws_master_root_volume_size" {
  type        = string
  description = "The size of the volume in gigabytes for the root block device of master nodes."
  default = 200
}

variable "aws_master_root_volume_iops" {
  type = string

  description = <<EOF
The amount of provisioned IOPS for the root block device of master nodes.
Ignored if the volume type is not io1.
EOF
  default = 0

}

variable "aws_worker_root_volume_type" {
  type        = string
  description = "The type of volume for the root block device of worker nodes."
  default = "gp2"
}

variable "aws_worker_root_volume_size" {
  type        = string
  description = "The size of the volume in gigabytes for the root block device of worker nodes."
  default = 200
}

variable "aws_worker_root_volume_iops" {
  type = string

  description = <<EOF
The amount of provisioned IOPS for the root block device of worker nodes.
Ignored if the volume type is not io1.
EOF
  default = 0

}

variable "aws_region" {
  type = string
  description = "The target AWS region for the cluster."
}

variable "aws_azs" {
  type = list(string)
  description = "The availability zones in which to create the nodes."
}

variable "aws_vpc" {
  type = string
  default = null
  description = "(optional) An existing network (VPC ID) into which the cluster should be installed."
}

variable "aws_public_subnets" {
  type = list(string)
  default = null
  description = "(optional) Existing public subnets into which the cluster should be installed."
}

variable "aws_private_subnets" {
  type = list(string)
  default = null
  description = "(optional) Existing private subnets into which the cluster should be installed."
}

variable "aws_publish_strategy" {
  type = string
  description = "The cluster publishing strategy, either Internal or External"
  default = "External"
}

variable "airgapped" {
  type = map(string)
  default = {
    enabled  = false
    repository = ""
  }
}
