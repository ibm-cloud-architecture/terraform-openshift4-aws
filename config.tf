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

variable "use_ipv4" {
  type    = bool
  default = true
  description = "not implemented"
}

variable "use_ipv6" {
  type    = bool
  default = false
  description = "not implemented"
}

variable "openshift_version" {
  type    = string
  default = "4.6.28"
}

variable "airgapped" {
  type = map(string)
  default = {
    enabled  = false
    repository = ""
  }
}

variable "proxy_config" {
  type = map(string)
  description = "Not implemented"
  default = {
    enabled    = false
    httpProxy  = "http://user:password@ip:port"
    httpsProxy = "http://user:password@ip:port"
    noProxy    = "ip1,ip2,ip3,.example.com,cidr/mask"
  }
}

variable "openshift_additional_trust_bundle" {
  description = "path to a file with all your additional ca certificates"
  type        = string
  default     = ""
}

variable "openshift_ssh_key" {
  description = "Path to SSH Public Key file to use for OpenShift Installation"
  type        = string
  default     = ""
}

variable "openshift_byo_dns" {
  description = "Do not deploy any public or private DNS zone into Azure"
  type        = bool
  default     = false
}