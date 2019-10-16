data "aws_route53_zone" "ocp_private" {
  zone_id = "${var.ocp_route53_private_zone_id}"
}

