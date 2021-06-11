variable "aws_config_version" {
  description = <<EOF
(internal) This declares the version of the AWS configuration variables.
It has no impact on generated assets but declares the version contract of the configuration.
EOF

  default = "1.0"
}

variable "aws_bootstrap_instance_type" {
  type        = string
  description = "Instance type for the bootstrap node. Default: `i3.xlarge`."
  default = "i3.xlarge"
}

variable "aws_master_instance_type" {
  type        = string
  description = "Instance type for the master node(s). Default: `m4.xlarge`."
  default     = "m5.xlarge"
}

variable "aws_worker_instance_type" {
  type        = string
  description = "Instance type for the worker node(s). Default: `m4.2xlarge`."
  default     = "m5.2xlarge"
}

variable "aws_infra_instance_type" {
  type        = string
  description = "Instance type for the worker node(s). Default: `m4.2xlarge`."
  default     = "m5.xlarge"
}

# variable "aws_ami" {
#   type        = string
#   description = "AMI for all nodes.  An encrypted copy of this AMI will be used.  Example: `ami-foobar123`."
# }

variable "aws_extra_tags" {
  type = map(string)

  description = <<EOF
(optional) Extra AWS tags to be applied to created resources.

Example: `{ "owner" = "me", "kubernetes.io/cluster/mycluster" = "owned" }`
EOF

  default = {}
}

variable "aws_master_root_volume_type" {
  type = string
  description = "The type of volume for the root block device of master nodes."
  default = "gp2"
}

variable "aws_master_root_volume_size" {
  type = string
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

variable "infra_count" {
  type    = string
  default = 0
}

variable "aws_infra_root_volume_type" {
  type        = string
  description = "The type of volume for the root block device of infra nodes."
  default = "gp2"
}

variable "aws_infra_root_volume_size" {
  type        = string
  description = "The size of the volume in gigabytes for the root block device of infra nodes."
  default = 200
}

variable "aws_infra_root_volume_iops" {
  type = string

  description = <<EOF
The amount of provisioned IOPS for the root block device of infra nodes.
Ignored if the volume type is not io1.
EOF
  default = 0

}

variable "aws_master_root_volume_encrypted" {
  type = bool
  default = true
  description = <<EOF
Indicates whether the root EBS volume for master is encrypted. Encrypted Amazon EBS volumes
may only be attached to machines that support Amazon EBS encryption.
EOF

}

variable "aws_master_root_volume_kms_key_id" {
  type = string

  description = <<EOF
(optional) Indicates the KMS key that should be used to encrypt the Amazon EBS volume.
If not set and root volume has to be encrypted, the default KMS key for the account will be used.
EOF

  default = ""
}

variable "aws_region" {
  type        = string
  description = "The target AWS region for the cluster."
}

variable "aws_azs" {
 type = list(string)
 description = "The availability zones in which to create the nodes."
 default = null
}

variable "aws_vpc" {
  type        = string
  default     = null
  description = "(optional) An existing network (VPC ID) into which the cluster should be installed."
}

variable "aws_public_subnets" {
  type        = list(string)
  default     = null
  description = "(optional) Existing public subnets into which the cluster should be installed."
}

variable "aws_private_subnets" {
  type        = list(string)
  default     = null
  description = "(optional) Existing private subnets into which the cluster should be installed."
}

variable "aws_publish_strategy" {
  type        = string
  description = "The cluster publishing strategy, either Internal or External"
  default = "External"
}

variable "aws_skip_region_validation" {
  type        = bool
  default     = false
  description = "This decides if the AWS provider should validate if the region is known."
}

# variable "aws_access_key_id" {
#   type        = string
#   description = "AWS Key"
# }

# variable "aws_secret_access_key" {
#   type        = string
#   description = "AWS Secret"
# }
