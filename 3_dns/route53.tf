resource "aws_route53_zone" "ocp_private" {
  name = "${var.clustername}.${var.domain}"
  vpc {
    vpc_id = "${data.aws_vpc.ocp_vpc.id}"
  }
  force_destroy = "true"

  tags = "${merge(
    var.default_tags, 
    map(
      "Name", "${var.clustername}.${var.domain}.",
      "kubernetes.io/cluster/${local.infrastructure_id}", "owned"
    )
  )}"
}

resource "aws_route53_record" "master_api_int" {
  name      = "api-int.${var.clustername}.${var.domain}"
  type      = "A"
  zone_id   = "${aws_route53_zone.ocp_private.zone_id}"

  alias {
    name                    = "${data.aws_lb.ocp_control_plane_int.dns_name}"
    zone_id                 = "${data.aws_lb.ocp_control_plane_int.zone_id}"
    evaluate_target_health  = true
  }
}

resource "aws_route53_record" "master_api" {
  name      = "api.${var.clustername}.${var.domain}"
  type      = "A"
  zone_id   = "${aws_route53_zone.ocp_private.zone_id}"

  alias {
    name                    = "${data.aws_lb.ocp_control_plane_int.dns_name}"
    zone_id                 = "${data.aws_lb.ocp_control_plane_int.zone_id}"
    evaluate_target_health  = true
  }
}

