# ==========================================
# 1. S3 BUCKET (Private Static Hosting)
# ==========================================
resource "aws_s3_bucket" "frontend" {
  bucket = var.bucket_name
  tags = {
    Name = "${var.prefix}-frontend-bucket"
  }
}
# Block all public access
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# ==========================================
# 2. ORIGIN ACCESS CONTROL (OAC)
# ==========================================
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.prefix}-oac"
  description                       = "OAC for ${var.prefix} frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
# ==========================================
# 3. CLOUDFRONT DISTRIBUTION
# ==========================================
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = var.default_root_object
  aliases             = [var.domain_name]
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.frontend.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.id}"
    viewer_protocol_policy = "redirect-to-https"
    # AWS Managed CachingOptimized Policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }
  # SPA Routing: Redirect 403 & 404 to /index.html with status 200
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/${var.default_root_object}"
    error_caching_min_ttl = 10
  }
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/${var.default_root_object}"
    error_caching_min_ttl = 10
  }
  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  tags = {
    Name = "${var.prefix}-frontend-cf"
  }
}

# ==========================================
# 4. S3 BUCKET POLICY (Grant CloudFront OAC)
# ==========================================
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
