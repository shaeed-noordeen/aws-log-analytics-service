# Terraform

This directory contains reusable infrastructure modules and environment compositions.

```
terraform/
  modules/    # Reusable Terraform modules (each has its own README)
  envs/       # Environment stacks such as prod (each has its own README)
```

## How to use this codebase

1. Review the module documentation under `terraform/modules/<module>/README.md` to understand inputs, outputs, and behaviour before consuming a module.
2. For a given environment (for example `terraform/envs/prod/`), check its README for stack-level details, prerequisites, and deployment guidance.
3. Run Terraform from the environment directory:

```bash
cd terraform/envs/<env>
terraform init
terraform plan
terraform apply
```

## Credentials

Provide AWS credentials via `AWS_PROFILE`, environment variables, or your preferred mechanism before running Terraform commands.
