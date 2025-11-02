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

variable "origin_id" {
  description = "Identifier used for the origin within the distribution."
  type        = string
  default     = "alb-origin"
}

variable "comment" {
  description = "Comment applied to the CloudFront distribution."
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "Default root object served by CloudFront."
  type        = string
  default     = "index.html"
}

variable "waf_name" {
  description = "WAF ACL name (defaults to <name>-waf)."
  type        = string
  default     = null
}

variable "ordered_cache_behaviors" {
  description = "Ordered cache behaviors to configure for the distribution."
  type = list(object({
    path_pattern          = string
    allowed_methods       = list(string)
    cached_methods        = list(string)
    viewer_protocol_policy = string
    min_ttl               = number
    default_ttl           = number
    max_ttl               = number
    forward_query_string  = bool
    forward_cookies       = string
  }))
  default = [
    {
      path_pattern           = "/analyze"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
      forward_query_string   = true
      forward_cookies        = "none"
    }
  ]
}
