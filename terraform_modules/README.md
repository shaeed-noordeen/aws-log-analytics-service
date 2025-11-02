# Terraform Modules

This directory houses the shared Terraform modules consumed by the Log Analyzer and Welcome Website stacks.

Current modules:

- `network/` - VPC, subnets, routes, and internet/NAT gateways.
- `iam/` - IAM roles and policies needed by the services.
- `ecr/` - ECR repository and lifecycle policy.
- `ecs_service/` - ECS task definition and Fargate service wiring.
- `alb/` - Application Load Balancer, target groups, and listeners.
- `cloudfront/` - CloudFront distribution configured for the ALB origin.
