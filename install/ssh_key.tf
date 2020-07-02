data "tls_public_key" "installkey" {
  private_key_pem = "${file(var.private_ssh_key_file)}"
}
