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

variable "repository_name" {
  description = "Optional explicit name for the ECR repository."
  type        = string
  default     = null
}
