output "name_servers" {
  description = "The 4 Route 53 Name Servers to configure in Cloudflare / parent DNS"
  value       = aws_route53_zone.primary.name_servers
}

output "zone_id" {
  description = "The Route 53 Hosted Zone ID"
  value       = aws_route53_zone.primary.zone_id
}

output "certificate_arn" {
  description = "The ARN of the validated ACM Certificate"
  value       = aws_acm_certificate_validation.cert.certificate_arn
}
