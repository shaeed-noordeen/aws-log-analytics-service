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

variable "container_image" {
  description = "Container image to deploy."
  type        = string
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
  description = "Security group IDs attached to ECS tasks."
  type        = list(string)
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

variable "additional_dependencies" {
  description = "Optional resources that the ECS service should depend on."
  type        = list(any)
  default     = []
}
