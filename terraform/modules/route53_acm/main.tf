# 1. The Route 53 Hosted Zone
resource "aws_route53_zone" "primary" {
  name = var.domain_name

  tags = {
    Name = "${var.prefix}-hosted-zone"
  }
}

# 2. ACM Certificate (Wildcard + Apex)
resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = {
    Name = "${var.prefix}-acm-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 3. DNS Validation Record in Route 53
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}

# 4. Wait for Certificate to be Issued
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
