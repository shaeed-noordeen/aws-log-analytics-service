locals {
  base_name = coalesce(var.service_name, var.name)

  task_role_name      = coalesce(var.task_role_name, "${local.base_name}-ecs-task-role")
  execution_role_name = coalesce(var.execution_role_name, "${local.base_name}-ecs-task-execution-role")
  s3_policy_name      = coalesce(var.s3_policy_name, "${local.base_name}-s3-access-policy")

  base_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  task_role_tags = merge(
    local.base_tags,
    {
      Name = local.task_role_name
    }
  )

  execution_role_tags = merge(
    local.base_tags,
    {
      Name = local.execution_role_name
    }
  )

  policy_tags = merge(
    local.base_tags,
    {
      Name = local.s3_policy_name
    }
  )

  allowed_bucket_arns = [
    for bucket in var.allowed_s3_buckets : format("arn:aws:s3:::%s", bucket)
  ]

  allowed_bucket_object_arns = [
    for bucket in var.allowed_s3_buckets : format("arn:aws:s3:::%s/*", bucket)
  ]
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = local.task_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.task_role_tags
}

resource "aws_iam_role" "execution_role" {
  name               = local.execution_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.execution_role_tags
}

resource "aws_iam_role_policy_attachment" "execution_role" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "s3_read" {
  count = var.attach_s3_read ? 1 : 0

  statement {
    actions   = ["s3:ListBucket"]
    resources = local.allowed_bucket_arns
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = local.allowed_bucket_object_arns
  }
}

resource "aws_iam_policy" "s3_read" {
  count       = var.attach_s3_read ? 1 : 0
  name        = local.s3_policy_name
  description = "S3 read-only access for ${local.base_name} tasks."
  policy      = data.aws_iam_policy_document.s3_read[0].json

  tags = local.policy_tags
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  count      = var.attach_s3_read ? 1 : 0
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.s3_read[0].arn
}
