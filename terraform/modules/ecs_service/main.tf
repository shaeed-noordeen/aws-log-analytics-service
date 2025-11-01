data "aws_region" "current" {}

locals {
  service_identifier = coalesce(var.name, var.service_name)

  common_tags = merge(
    {
      Name        = "${local.service_identifier}-${var.environment}"
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  log_group_name = "/ecs/${local.service_identifier}-${var.environment}"
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "this" {
  name = local.log_group_name

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${local.service_identifier}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = local.service_identifier
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = local.service_identifier
        }
      }
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "this" {
  name            = "${local.service_identifier}-${var.environment}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn == null ? [] : [var.target_group_arn]
    content {
      target_group_arn = load_balancer.value
      container_name   = local.service_identifier
      container_port   = var.container_port
    }
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = var.additional_dependencies

  tags = local.common_tags
}
