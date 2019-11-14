
resource "aws_route53_record" "etcd_a_int" {
  count     = "${lookup(var.control_plane, "count", 3)}"

  name      = "${format("etcd-%d.${var.clustername}.${var.domain}", count.index)}"
  type      = "A"
  zone_id   = "${data.aws_route53_zone.ocp_private.zone_id}"
  ttl       = 60

  records = [
      "${element(aws_instance.master.*.private_ip, count.index)}"
  ]
}

data "template_file" "etcd_srv" {
  count = "${lookup(var.control_plane, "count", 3)}"
  template = "${format("0 10 2380 etcd-%d.${var.clustername}.${var.domain}", count.index)}"
}

resource "aws_route53_record" "etcd_srv_int" {
  name      = "_etcd-server-ssl._tcp.${var.clustername}.${var.domain}"
  type      = "SRV"
  zone_id   = "${data.aws_route53_zone.ocp_private.zone_id}"
  ttl       = 60

  records = "${data.template_file.etcd_srv.*.rendered}"
}

data "aws_route53_zone" "ocp_private" {
  zone_id = "${var.ocp_route53_private_zone_id}"
}

