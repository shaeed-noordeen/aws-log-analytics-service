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

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "The number of Availability Zones to use."
  type        = number
  default     = 2
}

variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to."
  type        = string
}
