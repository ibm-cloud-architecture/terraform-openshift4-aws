data "aws_security_group" "master" {
    id = "${var.ocp_control_plane_security_group_id}"
}

data "aws_security_group" "worker" {
    id = "${var.ocp_worker_security_group_id}"
}