locals {
  base_name = coalesce(var.service_name, var.name)

  common_tags = merge(
    {
      Name        = "${local.base_name}-${var.environment}"
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
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
  name               = "${local.base_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role" "execution_role" {
  name               = "${local.base_name}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.common_tags
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
  name        = "${local.base_name}-s3-read"
  description = "S3 read-only access for ${local.base_name} tasks."
  policy      = data.aws_iam_policy_document.s3_read[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  count      = var.attach_s3_read ? 1 : 0
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.s3_read[0].arn
}
