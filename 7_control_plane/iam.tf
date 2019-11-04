data "aws_iam_instance_profile" "ocp_ec2_master_instance_profile" {
  name = "${var.ocp_master_instance_profile_id}"
}

data "aws_iam_instance_profile" "ocp_ec2_worker_instance_profile" {
  name = "${var.ocp_worker_instance_profile_id}"
}