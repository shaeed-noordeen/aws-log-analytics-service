# ALB Module

Creates an internet-facing Application Load Balancer with listeners, security group, and target group suitable for ECS services.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Base name for resources (service name). | `string` | n/a | yes |
| `environment` | Environment name, e.g. `dev`/`stage`/`prod`. | `string` | `"prod"` | no |
| `tags` | Extra tags to apply to all resources. | `map(string)` | `{}` | no |
| `vpc_id` | VPC ID for the load balancer. | `string` | n/a | yes |
| `public_subnet_ids` | Subnet IDs for ALB placement. | `list(string)` | n/a | yes |
| `certificate_arn` | ACM certificate ARN for HTTPS listener. | `string` | n/a | yes |
| `target_port` | Port that the target group forwards to. | `number` | `80` | no |
| `health_check_path` | HTTP path used for target group health checks. | `string` | `"/"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `alb_dns_name` | DNS name of the ALB. |
| `alb_zone_id` | Route 53 hosted zone ID for the ALB. |
| `alb_security_group_id` | Security group ID attached to the ALB. |
| `target_group_arn` | Target group ARN for ECS services/targets. |
| `listener` | HTTPS listener resource reference. |
