# ==========================================
# Root Environment Outputs: Demo
# ==========================================

output "frontend_url" {
  description = "The live HTTPS URL of the Vue 3 frontend application"
  value       = "https://${var.domain_name}"
}

output "api_url" {
  description = "The live HTTPS URL of the Flask REST API backend"
  value       = "https://api.${var.domain_name}"
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID (used for CI/CD cache invalidation)"
  value       = module.frontend_s3_cloudfront.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront default domain name"
  value       = module.frontend_s3_cloudfront.cloudfront_domain_name
}

output "s3_frontend_bucket" {
  description = "S3 bucket name hosting frontend assets"
  value       = module.frontend_s3_cloudfront.s3_bucket_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL connection endpoint"
  value       = module.rds.db_endpoint
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}
