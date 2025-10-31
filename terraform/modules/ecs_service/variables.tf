variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "cpu" {
  description = "The number of CPU units to reserve for the container."
  type        = number
  default     = 256
}

variable "memory" {
  description = "The amount of memory (in MiB) to reserve for the container."
  type        = number
  default     = 512
}

variable "image" {
  description = "The Docker image to use for the container."
  type        = string
}

variable "container_port" {
  description = "The port that the container listens on."
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "The desired number of tasks to run."
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of the private subnet IDs."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "The ID of the ALB's security group."
  type        = string
}

variable "target_group_arn" {
  description = "The ARN of the ALB target group."
  type        = string
}

variable "alb_listener" {
  description = "A reference to the ALB listener to ensure correct dependency order."
  type        = any
}

variable "task_execution_role_arn" {
  description = "The ARN of the ECS task execution role."
  type        = string
}

variable "task_role_arn" {
  description = "The ARN of the ECS task role."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}