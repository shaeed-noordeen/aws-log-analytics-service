# Network Module

Creates a VPC with public and private subnets across the requested Availability Zones, associated route tables, Internet/NAT gateways, and an S3 gateway endpoint. Also provisions a general-purpose application security group for downstream services.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Base name for resources (service name). | `string` | n/a | yes |
| `environment` | Environment name, e.g. `dev`/`stage`/`prod`. | `string` | `"prod"` | no |
| `tags` | Extra tags to apply to all resources. | `map(string)` | `{}` | no |
| `vpc_cidr` | CIDR block for the VPC. | `string` | `"10.0.0.0/16"` | no |
| `az_count` | Number of Availability Zones to span. | `number` | `2` | no |
| `aws_region` | AWS region (used for the S3 endpoint service). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC. |
| `public_subnet_ids` | IDs of the public subnets. |
| `private_subnet_ids` | IDs of the private subnets. |
| `app_security_group_id` | Security group intended for application workloads in the VPC. |
