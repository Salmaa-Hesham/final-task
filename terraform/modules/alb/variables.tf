variable "prefix" {
  type        = string
  description = "Prefix for resource naming and tags (e.g. salma-realworld)"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID for the ALB"
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the validated ACM certificate"
}

variable "container_port" {
  type        = number
  description = "Port exposed by the backend container (e.g. 8080)"
}

variable "health_check_path" {
  type        = string
  description = "Path for the ALB target group health check (e.g. /api/ping)"
}

variable "ssl_policy" {
  type        = string
  description = "SSL Policy for the HTTPS listener (e.g. ELBSecurityPolicy-2016-08)"
}
