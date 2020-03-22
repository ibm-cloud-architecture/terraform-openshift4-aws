variable "openshift_pull_secret" {
  type        = string
  default     = "./openshift_pull_secret.json"
}

variable "openshift_installer_url" {
  type        = string
  description = <<EOF
The URL to download OpenShift installer.

default is "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest"
To install a specific version, use https://mirror.openshift.com/pub/openshift-v4/clients/ocp/<version>
EOF
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
