# ECR Module

Creates an Elastic Container Registry repository with on-push image scanning and a lifecycle policy that retains the 30 most recent images.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Base name for resources (service name). | `string` | n/a | yes |
| `environment` | Environment name, e.g. `dev`/`stage`/`prod`. | `string` | `"prod"` | no |
| `tags` | Extra tags to apply to all resources. | `map(string)` | `{}` | no |
| `repository_name` | Optional explicit repository name. When omitted the module uses `<name>-<environment>`. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `repository_url` | Base URL of the created ECR repository. |
