output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer (for Route 53 A-record)"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the Application Load Balancer (for Route 53 Alias)"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "The ARN of the Target Group (needed by the ECS Service)"
  value       = aws_lb_target_group.backend.arn
}
