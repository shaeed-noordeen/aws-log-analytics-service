variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "alb_dns_name" {
  description = "The DNS name of the ALB."
  type        = string
}

variable "origin_hostname" {
  description = "Optional external DNS name for the origin."
  type        = string
  default     = null
}

variable "origin_verify_header_value" {
  description = "The value of the X-Origin-Verify header."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
