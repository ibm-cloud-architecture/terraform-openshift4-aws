locals {
    public_ssh_key = var.openshift_ssh_key == "" ? tls_private_key.installkey[0].public_key_openssh : file(var.openshift_ssh_key)
}

resource "tls_private_key" "installkey" {
  count     = var.openshift_ssh_key == "" ? 1 : 0

  algorithm   = "RSA"
  rsa_bits = 4096
}
