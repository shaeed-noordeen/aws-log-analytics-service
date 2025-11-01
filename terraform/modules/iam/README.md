# IAM Module

Creates IAM task and execution roles for ECS services, optionally attaching an S3 read-only policy to the task role.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Base name for resources (service name). Used when `service_name` is not provided. | `string` | `null` | conditionally |
| `environment` | Environment name, e.g. `dev`/`stage`/`prod`. | `string` | `"prod"` | no |
| `tags` | Extra tags to apply to all resources. | `map(string)` | `{}` | no |
| `service_name` | Service identifier used for IAM role and policy names. | `string` | n/a | yes |
| `attach_s3_read` | Attach an S3 read-only policy to the task role. | `bool` | `false` | no |
| `allowed_s3_buckets` | List of S3 bucket names the task role can read when `attach_s3_read` is `true`. | `list(string)` | `[]` | no |

When `attach_s3_read` is `true`, provide at least one entry in `allowed_s3_buckets`.

## Outputs

| Name | Description |
|------|-------------|
| `task_role_arn` | ARN of the ECS task role. |
| `execution_role_arn` | ARN of the ECS task execution role. |
