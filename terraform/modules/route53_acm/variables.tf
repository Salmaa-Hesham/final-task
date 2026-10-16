variable "prefix" {
  type        = string
  description = "Prefix for resource naming and tags (e.g. salma-realworld)"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the hosted zone and ACM certificate (e.g. app.salmah.pp.ua)"
}
