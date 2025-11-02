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
| `ecs_service_name` | ECS service name (defaults to `<service_name>-service`). | `string` | `null` | no |
| `task_definition_family` | Task definition family name (defaults to `<service_name>-task`). | `string` | `null` | no |
| `container_image` | Container image URI to deploy. | `string` | n/a | yes |
| `container_name` | Container name within the task definition (defaults to `<service_name>`). | `string` | `null` | no |
| `container_port` | Port exposed by the container. | `number` | `8080` | no |
| `task_role_arn` | IAM role ARN assumed by the task. | `string` | n/a | yes |
| `execution_role_arn` | IAM role ARN used by the ECS agent. | `string` | n/a | yes |
| `subnet_ids` | Subnet IDs for the service ENIs (must be in the same VPC). | `list(string)` | n/a | yes |
| `security_group_ids` | Security group IDs to attach to the ENIs (leave empty to let the module create one). | `list(string)` | `[]` | no |
| `service_security_group_name` | Name for the managed service security group when created. | `string` | `null` | no |
| `vpc_id` | VPC ID used when creating the managed service security group. | `string` | `null` | conditionally |
| `alb_security_group_id` | ALB security group allowed to reach the managed service security group. | `string` | `null` | conditionally |
| `cpu` | CPU units for the task definition. | `number` | `256` | no |
| `memory` | Memory (MiB) for the task definition. | `number` | `512` | no |
| `desired_count` | Desired number of running tasks. | `number` | `1` | no |
| `target_group_arn` | Optional ALB target group ARN to register the service with. | `string` | `null` | no |
| `log_group_name` | CloudWatch Logs group name (defaults to `/ecs/<service_name>`). | `string` | `null` | no |

Either `name` or `service_name` must be provided. When both are set, `service_name` takes precedence for resource naming.

If `security_group_ids` is left empty, you must supply `vpc_id` and `alb_security_group_id` so the module can create the ingress rules that mirror the legacy setup.

## Outputs

This module does not export any outputs.
