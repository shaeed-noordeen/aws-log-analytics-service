# ECS Service Module

Deploys an ECS Fargate cluster and service with a configurable task definition, container image, and networking configuration. Supports optional ALB integration by forwarding to a provided target group.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Base name for resources (service name). Used when `service_name` is not provided. | `string` | `null` | conditionally |
| `environment` | Environment name, e.g. `dev`/`stage`/`prod`. | `string` | `"prod"` | no |
| `tags` | Extra tags to apply to all resources. | `map(string)` | `{}` | no |
| `service_name` | Logical name for the ECS service and task definition family. | `string` | n/a | yes |
| `cluster_name` | ECS cluster name. | `string` | n/a | yes |
| `container_image` | Container image URI to deploy. | `string` | n/a | yes |
| `container_port` | Port exposed by the container. | `number` | `8080` | no |
| `task_role_arn` | IAM role ARN assumed by the task. | `string` | n/a | yes |
| `execution_role_arn` | IAM role ARN used by the ECS agent. | `string` | n/a | yes |
| `subnet_ids` | Subnet IDs for the service ENIs (must be in the same VPC). | `list(string)` | n/a | yes |
| `security_group_ids` | Security group IDs attached to the service ENIs. | `list(string)` | n/a | yes |
| `cpu` | CPU units for the task definition. | `number` | `256` | no |
| `memory` | Memory (MiB) for the task definition. | `number` | `512` | no |
| `desired_count` | Desired number of running tasks. | `number` | `1` | no |
| `target_group_arn` | Optional ALB target group ARN to register the service with. | `string` | `null` | no |
| `additional_dependencies` | Optional list of resources the service should depend on (e.g. listeners). | `list(any)` | `[]` | no |

Either `name` or `service_name` must be provided. When both are set, `service_name` takes precedence for resource naming.

## Outputs

This module does not export any outputs.
