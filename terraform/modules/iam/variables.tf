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
  description = "Service name used to build IAM resource names."
  type        = string
}

variable "attach_s3_read" {
  description = "Attach an S3 read-only policy to the task role."
  type        = bool
  default     = false
}

variable "allowed_s3_buckets" {
  description = "List of S3 bucket names the task role can read when attach_s3_read is true."
  type        = list(string)
  default     = []

  validation {
    condition     = var.attach_s3_read == false || length(var.allowed_s3_buckets) > 0
    error_message = "When attach_s3_read is true, provide at least one bucket in allowed_s3_buckets."
  }
}
