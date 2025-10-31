variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "logs_bucket_name" {
  description = "The name of the S3 bucket containing the logs."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}