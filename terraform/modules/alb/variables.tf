variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "A list of the public subnet IDs."
  type        = list(string)
}

variable "container_port" {
  description = "The port that the container listens on."
  type        = number
  default     = 8080
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate for the ALB."
  type        = string
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