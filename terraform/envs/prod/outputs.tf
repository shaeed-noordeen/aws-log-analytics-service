output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = module.cloudfront.cloudfront_domain_name
}

output "repository_url" {
  description = "The URL of the ECR repository."
  value       = module.ecr.repository_url
}