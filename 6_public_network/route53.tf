# the installer complains if you haven't delegated a subdomain to AWS (?!)
data "aws_route53_zone" "ocp_public" {
  name = "${var.domain}"
  private_zone = false
}
