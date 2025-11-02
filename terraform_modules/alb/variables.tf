variable "name" {
  description = "Base name for resources (service name)."
  type        = string
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

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs to attach the ALB to."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener."
  type        = string
}

variable "alb_name" {
  description = "Load balancer name (defaults to <name>-alb)."
  type        = string
  default     = null
}

variable "target_group_name" {
  description = "Target group name (defaults to <name>-tg)."
  type        = string
  default     = null
}

variable "security_group_name" {
  description = "ALB security group name (defaults to <name>-alb-sg)."
  type        = string
  default     = null
}

variable "target_port" {
  description = "Port that the target group forwards to."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used for target group health checks."
  type        = string
  default     = "/"
}
