output "public_dns_id" {
  value = data.aws_route53_zone.public[0].id
}
