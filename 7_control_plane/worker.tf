resource "aws_instance" "worker" {
  count         = "${var.use_worker_machinesets ? 0 : lookup(var.worker, "count", 3) }"

  ami           = "${data.aws_ami.rhcos.id}"
  instance_type = "${lookup(var.worker, "type", "m4.large")}"
  subnet_id     = "${element(data.aws_subnet.ocp_pri_subnet.*.id, count.index)}"
  iam_instance_profile = "${data.aws_iam_instance_profile.ocp_ec2_worker_instance_profile.name}"

  vpc_security_group_ids = [
    "${data.aws_security_group.worker.id}",
  ]

  root_block_device {
    volume_size = "${lookup(var.worker, "disk", 120)}"
  }

  associate_public_ip_address = false
  availability_zone = "${element(data.aws_availability_zone.aws_azs.*.name, count.index)}"

  tags = "${merge(
      var.default_tags, 
      map(
        "Name", "${format("${local.infrastructure_id}-worker%02d", count.index + 1)}",
        "kubernetes.io/cluster/${local.infrastructure_id}", "owned"
      )
  )}"
  user_data = <<EOF
${base64decode(var.worker_ign_64)}
EOF
}
