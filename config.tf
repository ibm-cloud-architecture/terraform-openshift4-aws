terraform {
  required_version = ">= 0.12"
}

variable "machine_cidr" {
  type = string

  description = <<EOF
The IP address space from which to assign machine IPs.
Default "10.0.0.0/16"
EOF
  default = "10.0.0.0/16"
}




variable "base_domain" {
  type = string

  description = <<EOF
The base DNS domain of the cluster. It must NOT contain a trailing period. Some
DNS providers will automatically add this if necessary.

Example: `openshift.example.com`.

Note: This field MUST be set manually prior to creating the cluster.
This applies only to cloud platforms.
EOF

}

variable "cluster_name" {
  type = string

  description = <<EOF
The name of the cluster. It will be suffixed by the base_domain to make cluster_domain.
EOF
}

variable "openshift_pull_secret" {
  type = string
  description = "File containing pull secret - get it from https://cloud.redhat.com/openshift/install/pull-secret"
}

variable "openshift_installer_url" {
  type = string
  description = "URL of the appropriate OpenShift installer under https://mirror.openshift.com/pub/openshift-v4/clients/ocp/"
}