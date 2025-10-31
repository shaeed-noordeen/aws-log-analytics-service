output "task_execution_role_arn" {
  description = "The ARN of the ECS task execution role."
  value       = aws_iam_role.task_execution_role.arn
}

output "task_role_arn" {
  description = "The ARN of the ECS task role."
  value       = aws_iam_role.task_role.arn
}