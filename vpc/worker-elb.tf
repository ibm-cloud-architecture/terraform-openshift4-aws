resource "aws_lb" "apps" {
  name                             = "${var.cluster_id}-apps"
  load_balancer_type               = "network"
  subnets                          = data.aws_subnet.public.*.id
  internal                         = false
  enable_cross_zone_load_balancing = true

  tags = merge(
    {
      "Name" = "${var.cluster_id}-apps"
    },
    var.tags,
  )

  timeouts {
    create = "20m"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_lb_target_group" "apps-tg" {
  name     = "${var.cluster_id}-apps-tg"
  protocol = "TCP"
  port     = 443
  vpc_id   = data.aws_vpc.cluster_vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.cluster_id}-apps-tg"
    },
    var.tags,
  )

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    port                = 443
    protocol            = "HTTPS"
    path                = "/readyz"
  }
}

resource "aws_lb_target_group" "apps-tgns" {
  name     = "${var.cluster_id}-apps-tgns"
  protocol = "HTTP"
  port     = 80
  vpc_id   = data.aws_vpc.cluster_vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.cluster_id}-apps-tgns"
    },
    var.tags,
  )

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    port                = 80
    protocol            = "HTTP"
    path                = "/readyz"
  }
}

resource "aws_lb_listener" "apps-ns" {
  load_balancer_arn = aws_lb.apps.arn
  protocol          = "TCP"
  port              = "80"

  default_action {
    target_group_arn = aws_lb_target_group.apps-tgns.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "apps-s" {
  load_balancer_arn = aws_lb.apps.arn
  protocol          = "TCP"
  port              = "443"

  default_action {
    target_group_arn = aws_lb_target_group.apps-tg.arn
    type             = "forward"
  }
}

