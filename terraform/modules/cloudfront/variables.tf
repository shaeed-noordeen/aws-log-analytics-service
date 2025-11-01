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

variable "origin_domain_name" {
  description = "Domain name of the CloudFront origin."
  type        = string
}

variable "origin_protocol_policy" {
  description = "Protocol policy CloudFront uses to reach the origin."
  type        = string
  default     = "https-only"
}

variable "custom_origin_header_name" {
  description = "Optional header name to send to the origin."
  type        = string
  default     = null

  validation {
    condition = (
      var.custom_origin_header_name == null && var.custom_origin_header_value == null
    ) || (
      var.custom_origin_header_name != null && var.custom_origin_header_value != null
    )

    error_message = "Provide both header name and value, or leave both null."
  }
}

variable "custom_origin_header_value" {
  description = "Optional header value to send to the origin."
  type        = string
  default     = null
}
