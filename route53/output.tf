output "public_dns_id" {
  #value = local.public_endpoints ? data.aws_route53_zone.public[0].id : "nopublic"
  value = data.aws_route53_zone.public[0].id
}
