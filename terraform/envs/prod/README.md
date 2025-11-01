# Production Environment

This environment deploys the Log Analyzer service stack in the `prod` workspace. It assembles the reusable modules under `terraform/modules/` to provide networking, container registry, IAM roles, ECS service, ALB, and CloudFront distribution.

## Components

- **Network** – VPC, public/private subnets across two AZs, NAT gateways, S3 gateway endpoint, and a reusable application security group.
- **ECR** – Repository for the application container images, retaining the 30 most recent images.
- **IAM** – ECS task execution role plus a task role with optional S3 read access to the logs bucket.
- **ALB** – HTTPS load balancer restricted to CloudFront, health checking the service on `/healthz`.
- **ECS Service** – Fargate cluster and service running the log analyzer container image from ECR.
- **CloudFront** – Global distribution pointing to the ALB with an origin verification header and managed WAF.

## Prerequisites

- Remote state backend (S3 bucket and DynamoDB table) configured per `backend.tf`.
- ACM certificate in the target region covering the ALB domain (`*.shaeed.co.uk`).
- Secrets Manager secret `prod/alb/verify` containing the origin verification header expected by the ALB listener.
- AWS credentials with permissions to manage the above resources.

## Deploying

```bash
cd terraform/envs/prod
terraform init
terraform plan -var="image_tag=<tag>"
terraform apply -var="image_tag=<tag>"
```

- `image_tag` defaults to `latest`; CI typically supplies a commit SHA.
- `origin_hostname` defaults to `alb-origin.shaeed.co.uk` and can be overridden to point CloudFront at an alternate domain.

## Outputs

After apply, key outputs include:

- `cloudfront_domain_name` – External distribution domain for the service.
- `repository_url` – Base URI of the ECR repository containing the application images.

Retrieve output values with:

```bash
terraform -chdir=terraform/envs/prod output -raw <name>
```
