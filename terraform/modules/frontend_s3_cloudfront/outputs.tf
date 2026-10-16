output "s3_bucket_name" {
  description = "Name of the S3 bucket (needed for CI/CD sync)"
  value       = aws_s3_bucket.frontend.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.frontend.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution (needed for CI/CD cache invalidation)"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution (needed by Route 53 A-record Alias)"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront Route 53 hosted zone ID (always Z2FDTNDATAQYW2 for CloudFront alias targets)"
  value       = aws_cloudfront_distribution.frontend.hosted_zone_id
}
