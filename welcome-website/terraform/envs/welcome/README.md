# Welcome Environment

This environment provisions the `welcome-web` static site stack backed by ECS Fargate, an internet-facing ALB, and a CloudFront distribution.

## Components

- **Network** - Shared VPC, public/private subnets, and Internet/NAT gateway plumbing via the reusable `network` module.
- **ECR** - Repository for the `welcome-web` container image.
- **IAM** - Task execution and task roles dedicated to the service.
- **ECS Service** - Fargate service running the Nginx container listening on port 80.
- **ALB** - HTTPS listener forwarding traffic to the service with health checks on `/`.
- **CloudFront** - Distribution fronting the ALB and serving traffic from the default CloudFront domain.

## Configuration Notes

- `image_tag` defaults to `latest`. CI will typically pin this to a specific build.
- Set `origin_hostname` if CloudFront should point at an alternate origin instead of the ALB DNS name.
