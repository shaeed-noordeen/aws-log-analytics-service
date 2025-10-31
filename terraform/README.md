# Terraform README

The `terraform/` directory manages all AWS infrastructure required for the Log Analytics Service. It follows a module-per-component approach with a single production environment.

## Layout

```
terraform/
├── envs/
│   └── prod/
│       ├── backend.tf          # Remote S3/DynamoDB state backend
│       ├── data.tf             # Shared data sources (ACM cert, secrets)
│       ├── main.tf             # Environment composition
│       ├── outputs.tf
│       ├── providers.tf
│       └── variables.tf
└── modules/
    ├── network/                # VPC, subnets, NAT, S3 endpoint
    ├── alb/                    # Application Load Balancer + SG
    ├── ecs_service/            # ECS cluster, Fargate service & SG
    ├── ecr/                    # Elastic Container Registry repo
    ├── iam/                    # ECS task execution + task roles
    └── cloudfront/             # CloudFront distribution + WAF
```

### Module Overview

| Module        | Purpose                                                                                   | Key Outputs                         |
|---------------|-------------------------------------------------------------------------------------------|-------------------------------------|
| `network`     | Public/private subnets across AZs, NAT gateways, S3 gateway endpoint with route bindings. | `vpc_id`, `public_subnet_ids`, `private_subnet_ids` |
| `alb`         | Internet-facing HTTPS ALB restricted to CloudFront via managed prefix list.               | `alb_dns_name`, `alb_zone_id`, `target_group_arn` |
| `ecs_service` | Fargate service running the log analyzer container, wired to ALB target group.            | `service_name`, `cluster_id`        |
| `ecr`         | Repository with lifecycle policy retaining the last 30 images.                           | `repository_url`                    |
| `iam`         | Execution + task roles with S3 read permissions for the logs bucket.                      | `task_execution_role_arn`, `task_role_arn` |
| `cloudfront`  | Distribution fronting the ALB, custom header auth, WAF ACL, optional origin hostname.     | `cloudfront_domain_name`            |

## Backend & Providers

State is stored remotely in the S3 bucket / DynamoDB table defined in `backend.tf`. Ensure they exist before running `terraform init`. The CloudFront module requires a us-east-1 provider alias (`providers.tf`).

## Running Terraform

```bash
cd terraform/envs/prod
terraform init
terraform plan -var="image_tag=<tag>"
terraform apply -var="image_tag=<tag>"
```

Variables of interest:
- `image_tag` – Docker image tag in ECR (default `latest`; CI supplies the commit SHA).
- `origin_hostname` – External host CloudFront uses to reach the ALB (`alb-origin.shaeed.co.uk` by default).

`AWS_PROFILE` or standard `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` environment variables must be set.

## Outputs

Key outputs include:
- `cloudfront_domain_name` – CloudFront distribution domain.
- `alb_dns_name` – ALB DNS (used when creating the external CNAME).
- `repository_url` – ECR repository base URL.

Retrieve any output via:
```bash
terraform -chdir=terraform/envs/prod output -raw <name>
```

## CI/CD Integration

`deploy.yml` runs `terraform apply` on merges to `main`, passing the freshly built image tag and performing a smoke test. `infrastructure-ci.yml` executes `terraform plan` on internal pull requests and comments the plan on the PR.

## Notes & Limitations

- DNS management for `alb-origin.shaeed.co.uk` is external (GoDaddy). Terraform expects the record to exist but does not create it.
- The ALB certificate must cover the CloudFront origin hostname (`*.shaeed.co.uk`).
- Adding more environments involves creating additional directories under `envs/` and reusing the modules.
- Remote backend credentials are not stored in GitHub; configure them locally via `aws configure` or environment variables.
