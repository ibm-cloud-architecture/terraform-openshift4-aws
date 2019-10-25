

resource "aws_security_group" "master" {
  name = "${local.infrastructure_id}-master"
  vpc_id = "${data.aws_vpc.ocp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.infrastructure_id}-master",
      "kubernetes.io/cluster/${local.infrastructure_id}", "shared"
    )
  )}"
}

resource "aws_security_group_rule" "master_icmp" {
  type        = "ingress"

  from_port   = 0
  to_port     = 0
  protocol    = "icmp"
  cidr_blocks = [
    "${data.aws_vpc.ocp_vpc.cidr_block}"
  ]
  
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_ssh" {
  type        = "ingress"

  from_port   = 22 
  to_port     = 22 
  protocol    = "tcp"
  cidr_blocks = [
    "${data.aws_vpc.ocp_vpc.cidr_block}"
  ]
  
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_6443" {
  type        = "ingress"

  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  cidr_blocks = [
    "${data.aws_vpc.ocp_vpc.cidr_block}"
  ]
  
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_22623" {
  type        = "ingress"

  from_port   = 22623
  to_port     = 22623
  protocol    = "tcp"
  cidr_blocks = [
    "${data.aws_vpc.ocp_vpc.cidr_block}"
  ]
  
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_etcd" {
  type        = "ingress"

  from_port   = 2379
  to_port     = 2380
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.master.id}"
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_master_vxlan" {
  type        = "ingress"

  from_port   = 4789
  to_port     = 4789
  protocol    = "udp"

  source_security_group_id = "${aws_security_group.master.id}"
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_worker_vxlan" {
  type        = "ingress"

  from_port   = 4789
  to_port     = 4789
  protocol    = "udp"

  source_security_group_id = "${aws_security_group.worker.id}"
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_master_internal" {
  type        = "ingress"

  from_port   = 9000
  to_port     = 9999
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.master.id}"
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_worker_internal" {
  type        = "ingress"

  from_port   = 9000
  to_port     = 9999
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.worker.id}"
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_master_kube" {
  type        = "ingress"

  from_port   = 10250
  to_port     = 10259
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.master.id}"
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_worker_kube" {
  type        = "ingress"

  from_port   = 10250
  to_port     = 10259
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.worker.id}"
  security_group_id = "${aws_security_group.master.id}"
}

# TODO i don't like this
resource "aws_security_group_rule" "master_master_nodeport" {
  type        = "ingress"

  from_port   = 30000
  to_port     = 32767
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.master.id}"
  security_group_id = "${aws_security_group.master.id}"
}

# TODO i don't like this
resource "aws_security_group_rule" "master_worker_nodeport" {
  type        = "ingress"

  from_port   = 30000
  to_port     = 32767
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.worker.id}"
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_egress" {
  type        = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group" "worker" {
  name = "${local.infrastructure_id}-worker"
  vpc_id = "${data.aws_vpc.ocp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map(
      "Name", "${local.infrastructure_id}-worker",
      "kubernetes.io/cluster/${local.infrastructure_id}", "shared"
    )
  )}"
}

resource "aws_security_group_rule" "worker_icmp" {
  type        = "ingress"

  from_port   = 0
  to_port     = 0
  protocol    = "icmp"
  cidr_blocks = [
    "${data.aws_vpc.ocp_vpc.cidr_block}"
  ]
  
  security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "worker_443" {
  type        = "ingress"

  from_port     = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = [
    "${data.aws_vpc.ocp_vpc.cidr_block}"
  ]

  security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "worker_80" {
  type        = "ingress"

  from_port     = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = [
    "${data.aws_vpc.ocp_vpc.cidr_block}"
  ]

  security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "worker_ssh" {
  type        = "ingress"

  from_port   = 22 
  to_port     = 22 
  protocol    = "tcp"
  cidr_blocks = [
    "${data.aws_vpc.ocp_vpc.cidr_block}"
  ]
  
  security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "worker_master_vxlan" {
  type        = "ingress"

  from_port   = 4789
  to_port     = 4789
  protocol    = "udp"

  source_security_group_id = "${aws_security_group.master.id}"
  security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "worker_worker_vxlan" {
  type        = "ingress"

  from_port   = 4789
  to_port     = 4789
  protocol    = "udp"

  source_security_group_id = "${aws_security_group.worker.id}"
  security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "worker_master_internal" {
  type        = "ingress"

  from_port   = 9000
  to_port     = 9999
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.master.id}"
  security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "worker_worker_internal" {
  type        = "ingress"

  from_port   = 9000
  to_port     = 9999
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.worker.id}"
  security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "worker_worker_kube" {
  type        = "ingress"

  from_port   = 10250
  to_port     = 10250
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.worker.id}"
  security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "worker_master_kube" {
  type        = "ingress"

  from_port   = 10250
  to_port     = 10250
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.master.id}"
  security_group_id = "${aws_security_group.worker.id}"
}

# TODO i don't like this
resource "aws_security_group_rule" "worker_worker_nodeport" {
  type        = "ingress"

  from_port   = 30000
  to_port     = 32767
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.worker.id}"
  security_group_id = "${aws_security_group.worker.id}"
}

# TODO i don't like this
resource "aws_security_group_rule" "worker_master_nodeport" {
  type        = "ingress"

  from_port   = 30000
  to_port     = 32767
  protocol    = "tcp"

  source_security_group_id = "${aws_security_group.master.id}"
  security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "worker_egress" {
  type        = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  
  security_group_id = "${aws_security_group.worker.id}"
}
