locals {
  sanitized_name          = replace(lower(var.name), "/[^a-z0-9-]/", "-")
  resolved_alb_name       = substr(coalesce(var.alb_name, "${local.sanitized_name}-alb"), 0, 32)
  resolved_target_name    = substr(coalesce(var.target_group_name, "${local.sanitized_name}-tg"), 0, 32)
  resolved_security_group = coalesce(var.security_group_name, "${local.sanitized_name}-alb-sg")

  base_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  lb_tags = merge(
    local.base_tags,
    {
      Name = local.resolved_alb_name
    }
  )

  target_group_tags = merge(
    local.base_tags,
    {
      Name = local.resolved_target_name
    }
  )

  security_group_tags = merge(
    local.base_tags,
    {
      Name = local.resolved_security_group
    }
  )
}

resource "aws_lb" "main" {
  name               = local.resolved_alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = local.lb_tags
}

resource "aws_security_group" "alb" {
  name        = local.resolved_security_group
  description = "Allow HTTP and HTTPS traffic to the ALB."
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.security_group_tags
}

resource "aws_lb_target_group" "main" {
  name        = local.resolved_target_name
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.target_group_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Cannot connect via HTTP."
      status_code  = "403"
    }
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
