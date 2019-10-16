#data "ignition_config" "control_plane_ign" {
#  replace {
#    source = "s3://${aws_s3_bucket.ocp_ignition.id}/master.ign"
#  }
#}

resource "aws_instance" "master" {
  # if master nodes are already created, don't trigger a destroy/recreate if we don't
  # have to, which are triggered on user_data changes
  count         = "${lookup(var.control_plane, "count", 3)}"

  ami           = "${data.aws_ami.rhcos.id}"
  instance_type = "${lookup(var.control_plane, "type", "m4.xlarge")}"
  subnet_id     = "${element(data.aws_subnet.ocp_pri_subnet.*.id, count.index)}"
  iam_instance_profile = "${data.aws_iam_instance_profile.ocp_ec2_master_instance_profile.name}"

  vpc_security_group_ids = [
    "${data.aws_security_group.master.id}",
  ]

  root_block_device {
    volume_size = "${lookup(var.control_plane, "disk", 120)}"
  }

  associate_public_ip_address = false
  availability_zone = "${element(data.aws_availability_zone.aws_azs.*.name, count.index)}"

  tags = "${merge(
      var.default_tags, 
      map(
        "Name", "${format("${local.infrastructure_id}-master%02d", count.index + 1)}",
        "kubernetes.io/cluster/${local.infrastructure_id}", "shared"
      )
  )}"
  user_data = <<EOF
${base64decode(var.master_ign_64)}
EOF
}

