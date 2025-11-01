output "alb_dns_name" {
  description = "The DNS name of the ALB."
  value       = aws_lb.main.dns_name
}

output "alb_security_group_id" {
  description = "The ID of the ALB's security group."
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "The ARN of the ALB target group."
  value       = aws_lb_target_group.main.arn
}

output "listener" {
  description = "A reference to the ALB listener to ensure correct dependency order."
  value       = aws_lb_listener.https
}

output "alb_zone_id" {
  description = "The Route 53 hosted zone ID for the ALB."
  value       = aws_lb.main.zone_id
}
