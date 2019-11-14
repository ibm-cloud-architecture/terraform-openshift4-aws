data "ignition_config" "bootstrap_ign" {
  replace {
    source = "s3://${aws_s3_bucket.ocp_ignition.id}/bootstrap.ign"
  }
}

resource "aws_instance" "bootstrap" {
  depends_on = [
    "null_resource.generate_ignition_config",
    "aws_s3_bucket_object.bootstrap_ign"
  ]

  ami           = "${data.aws_ami.rhcos.id}"
  instance_type = "${lookup(var.bootstrap, "type", "i3.xlarge")}"
  subnet_id     = "${data.aws_subnet.ocp_pri_subnet.0.id}"
  iam_instance_profile = "${aws_iam_instance_profile.ocp_ec2_bootstrap_instance_profile.name}"

  vpc_security_group_ids = "${concat(
    aws_security_group.bootstrap.*.id,
    list(data.aws_security_group.master.id)
  )}"

  availability_zone = "${element(data.aws_availability_zone.aws_azs.*.name, 0)}"

  tags = "${merge(
      var.default_tags, 
      map("Name",  "${format("${local.infrastructure_id}-bootstrap")}")
  )}"
  user_data = <<EOF
${data.ignition_config.bootstrap_ign.rendered}
EOF
}

