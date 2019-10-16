output "infrastructure_id" {
    value = "${local.infrastructure_id}"
}

output "clustername" {
    value = "${var.clustername}"
}

output "ocp_master_instance_profile_id" {
    value = "${aws_iam_instance_profile.ocp_ec2_master_instance_profile.id}"
}

output "ocp_worker_instance_profile_id" {
    value = "${aws_iam_instance_profile.ocp_ec2_worker_instance_profile.id}"
}