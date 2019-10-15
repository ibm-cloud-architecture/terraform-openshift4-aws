data "aws_vpc" "ocp_vpc" {
  id = "${var.private_vpc_id}"
}
