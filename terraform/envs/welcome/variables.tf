variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to."
  type        = string
  default     = "eu-north-1"
}

variable "image_tag" {
  description = "The Docker image tag to deploy."
  type        = string
  default     = "latest"
}

variable "origin_hostname" {
  description = "Optional attachment of external DNS name that CloudFront should use to reach the ALB."
  type        = string
  default     = ""
}
