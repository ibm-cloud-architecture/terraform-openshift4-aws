output "infrastructure_id" {
    value = "${local.infrastructure_id}"
}

output "clustername" {
    value = "${var.clustername}"
}

output "ocp_control_plane_security_group_id" {
    value = "${aws_security_group.master.id}"
}

output "ocp_worker_security_group_id" {
    value = "${aws_security_group.worker.id}"
}