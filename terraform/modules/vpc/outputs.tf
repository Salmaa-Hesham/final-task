output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets (for ALB)"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_app_subnet_ids" {
  description = "List of IDs of private app subnets (for ECS)"
  value       = [for s in aws_subnet.private_app : s.id]
}

output "isolated_db_subnet_ids" {
  description = "List of IDs of isolated database subnets (for RDS)"
  value       = [for s in aws_subnet.isolated_db : s.id]
}

output "alb_security_group_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for the ECS backend"
  value       = aws_security_group.ecs_backend.id
}

output "rds_security_group_id" {
  description = "Security group ID for the RDS PostgreSQL database"
  value       = aws_security_group.rds.id
}
