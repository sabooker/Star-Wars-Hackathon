resource "aws_lb" "windows_alb" {
  name               = "${var.environment_name}-windows-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "windows_tg" {
  name     = "${var.environment_name}-windows-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"
}

resource "aws_lb_listener" "windows_listener" {
  load_balancer_arn = aws_lb.windows_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.windows_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "windows_targets" {
  for_each = toset(flatten(var.windows_targets))

  target_group_arn = aws_lb_target_group.windows_tg.arn
  target_id        = each.value
  port             = 80
}

resource "aws_lb" "linux_alb" {
  name               = "${var.environment_name}-linux-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "linux_tg" {
  name     = "${var.environment_name}-linux-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"
}

resource "aws_lb_listener" "linux_listener" {
  load_balancer_arn = aws_lb.linux_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.linux_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "linux_targets" {
  for_each = toset(flatten(var.linux_targets))

  target_group_arn = aws_lb_target_group.linux_tg.arn
  target_id        = each.value
  port             = 80
}
