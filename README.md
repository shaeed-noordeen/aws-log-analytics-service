# AWS Log & Web Service Stack

This repository contains **two services** that run on AWS by reusing the shared infrastructure modules under `terraform_modules/`.

## Services

### 1. Log Analyzer
- **What it is:** A Python service that reads JSONL logs (local or from S3), counts errors by service, and raises an alert when a threshold is reached.
- **Where:** `log_analyzer/app/`
- **How it's deployed:** `log_analyzer/app/terraform/envs/prod/`
- **Docs:** [Service README](log_analyzer/app/README.md)

### 2. Welcome Website
- **What it is:** A simple containerised "Welcome / Hello" HTTP endpoint to prove the same infra pattern works for a static or lightweight service.
- **Where:** `welcome-website/app/`
- **How it's deployed:** `welcome-website/terraform/envs/welcome/`
- **Docs:** [Terraform env README](welcome-website/terraform/README.md)

## Infrastructure

- **Shared modules:** `terraform_modules/` - reusable building blocks covering VPC/network, IAM roles for ECS, ECS service, ALB, and CloudFront.
  - [Modules README](terraform_modules/README.md)
- **Environments:** each service uses its own Terraform environment folder so deployments stay independent:
  - `log_analyzer/app/terraform/envs/prod/`
  - `welcome-website/terraform/envs/welcome/`
- **Pattern:** both services run behind an ALB, with CloudFront as the public entry point.

## CI/CD

- **GitHub Actions** build the Docker image, push it to ECR, then run `terraform apply` against the corresponding environment.
- **Pull requests** run `terraform plan` (infra CI) for visibility and Python lint/tests via application CI.
