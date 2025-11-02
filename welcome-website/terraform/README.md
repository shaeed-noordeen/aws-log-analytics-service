# Terraform

This directory contains the environment definitions for the Welcome Website service.

```
welcome-website/terraform/
  envs/
    welcome/
      README.md
      *.tf
```

## How to use this codebase

1. Review the shared module documentation under `terraform_modules/<module>/README.md` to understand inputs, outputs, and behaviour before consuming a module.
2. For a given environment (for example `welcome-website/terraform/envs/welcome/`), check its README for stack-level details, prerequisites, and deployment guidance.
3. Run Terraform from the environment directory:

```bash
cd welcome-website/terraform/envs/<env>
terraform init
terraform plan
terraform apply
```

## Credentials

Provide AWS credentials via `AWS_PROFILE`, environment variables, or your preferred mechanism before running Terraform commands.
