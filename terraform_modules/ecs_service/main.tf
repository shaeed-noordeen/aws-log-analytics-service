data "aws_region" "current" {}

locals {
  service_identifier             = coalesce(var.service_name, var.name)
  container_name                 = coalesce(var.container_name, local.service_identifier)
  ecs_service_name               = coalesce(var.ecs_service_name, "${local.service_identifier}-service")
  task_family                    = coalesce(var.task_definition_family, "${local.service_identifier}-task")
  log_group_name                 = coalesce(var.log_group_name, "/ecs/${local.service_identifier}")
  create_service_security_group  = length(var.security_group_ids) == 0
  service_security_group_name    = coalesce(var.service_security_group_name, "${local.service_identifier}-ecs-service-sg")

  base_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  cluster_tags = merge(
    local.base_tags,
    {
      Name = var.cluster_name
    }
  )

  log_group_tags = merge(
    local.base_tags,
    {
      Name = local.log_group_name
    }
  )

  task_definition_tags = merge(
    local.base_tags,
    {
      Name = local.task_family
    }
  )

  service_tags = merge(
    local.base_tags,
    {
      Name = local.ecs_service_name
    }
  )

  security_group_tags = merge(
    local.base_tags,
    {
      Name = local.service_security_group_name
    }
  )
}

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  tags = local.cluster_tags
}

resource "aws_cloudwatch_log_group" "main" {
  name = local.log_group_name

  tags = local.log_group_tags
}

resource "aws_ecs_task_definition" "main" {
  family                   = local.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = local.container_name
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
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = local.container_name
        }
      }
    }
  ])

  tags = local.task_definition_tags
}

resource "aws_security_group" "ecs_service" {
  count       = local.create_service_security_group ? 1 : 0
  name        = local.service_security_group_name
  description = "Allow traffic from the ALB to the ECS service."
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.security_group_tags
}

resource "aws_ecs_service" "main" {
  name            = local.ecs_service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = local.create_service_security_group ? [aws_security_group.ecs_service[0].id] : var.security_group_ids
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn == null ? [] : [var.target_group_arn]
    content {
      target_group_arn = load_balancer.value
      container_name   = local.container_name
      container_port   = var.container_port
    }
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = local.service_tags
}
