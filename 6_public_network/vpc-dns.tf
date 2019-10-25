resource "aws_route53_zone_association" "public_vpc" {
  zone_id = "${var.ocp_route53_private_zone_id}"
  vpc_id  = "${var.public_vpc_id}"
}
