variable "prefix" {
  type        = string
  description = "Prefix for resource naming and tags (e.g. salma-realworld)"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for frontend assets (e.g. salma-realworld-frontend-253650698585)"
}

variable "domain_name" {
  type        = string
  description = "Custom domain name / alias for CloudFront (e.g. app.salmah.pp.ua)"
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the validated ACM certificate for CloudFront"
}

variable "default_root_object" {
  type        = string
  description = "Default root object for CloudFront and SPA error fallback"
}
