resource "tls_private_key" "installkey" {
  algorithm   = "RSA"
  rsa_bits = 4096
}
