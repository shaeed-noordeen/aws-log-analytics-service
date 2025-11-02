variable "name" {
  description = "Base name for resources (service name)."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name, e.g. dev/stage/prod."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Extra tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "service_name" {
  description = "Logical name of the ECS service."
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster to create."
  type        = string
}

variable "ecs_service_name" {
  description = "Name to assign to the ECS service (defaults to <service_name>-service)."
  type        = string
  default     = null
}

variable "task_definition_family" {
  description = "Task definition family name (defaults to <service_name>-task)."
  type        = string
  default     = null
}

variable "container_image" {
  description = "Container image to deploy."
  type        = string
}

variable "container_name" {
  description = "Container name inside the task definition (defaults to <service_name>)."
  type        = string
  default     = null
}

variable "container_port" {
  description = "Port exposed by the container."
  type        = number
  default     = 8080
}

variable "task_role_arn" {
  description = "IAM role ARN assumed by the task."
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN used by ECS agent."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS tasks."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the tasks. Leave empty to let the module create one."
  type        = list(string)
  default     = []
}

variable "service_security_group_name" {
  description = "Name for the managed service security group when created."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID used when creating the managed service security group."
  type        = string
  default     = null

  validation {
    condition     = length(var.security_group_ids) > 0 || var.vpc_id != null
    error_message = "Provide vpc_id when security_group_ids is empty to allow the module to create a security group."
  }
}

variable "alb_security_group_id" {
  description = "ALB security group ID allowed to reach the service security group."
  type        = string
  default     = null

  validation {
    condition     = length(var.security_group_ids) > 0 || var.alb_security_group_id != null
    error_message = "Provide alb_security_group_id when security_group_ids is empty so ingress can be configured."
  }
}

variable "cpu" {
  description = "CPU units for the task definition."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory (MiB) for the task definition."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of tasks to run."
  type        = number
  default     = 1
}

variable "target_group_arn" {
  description = "Optional target group ARN for the service load balancer."
  type        = string
  default     = null
}

variable "log_group_name" {
  description = "CloudWatch Logs group name (defaults to /ecs/<service_name>)."
  type        = string
  default     = null
}
