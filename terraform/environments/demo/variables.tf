# ==========================================
# Root Environment Variables: Demo
# ==========================================

variable "prefix" {
  type        = string
  description = "Prefix for all resources (e.g. salma-realworld)"
}

variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
}

variable "domain_name" {
  type        = string
  description = "Primary domain name for the application (e.g. app.salmah.pp.ua)"
}

# --- VPC & Networking ---
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Public subnets map"
}

variable "private_app_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Private application subnets map"
}

variable "isolated_db_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Isolated database subnets map"
}

variable "nat_gateway_subnet_key" {
  type        = string
  description = "The public_subnets map key where the single NAT Gateway is placed"
}

variable "alb_ingress_ports" {
  type        = list(number)
  description = "List of ports allowed for ALB ingress"
}

variable "db_port" {
  type        = number
  description = "PostgreSQL port"
}

# --- ALB ---
variable "health_check_path" {
  type        = string
  description = "Health check path for backend target group (e.g. /api/ping)"
}

variable "ssl_policy" {
  type        = string
  description = "SSL policy for HTTPS listener"
}

# --- RDS PostgreSQL ---
variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_username" {
  type        = string
  description = "Master database username"
}

variable "db_engine_version" {
  type        = string
  description = "PostgreSQL engine version"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
}

variable "enable_read_replica" {
  type        = bool
  default     = false
  description = "Whether to create a read replica for the RDS database"
}

variable "replica_instance_class" {
  type        = string
  default     = null
  description = "Instance class for the read replica"
}

variable "backup_retention_period" {
  type        = number
  default     = 1
  description = "Backup retention period in days for the primary DB"
}

# --- ECS Fargate ---
variable "container_image" {
  type        = string
  description = "ECR Docker image URI for backend"
}

variable "container_port" {
  type        = number
  description = "Port exposed by the backend container"
}

variable "ecs_cpu" {
  type        = string
  description = "Fargate task CPU units"
}

variable "ecs_memory" {
  type        = string
  description = "Fargate task memory in MB"
}

variable "ecs_desired_count" {
  type        = number
  description = "Desired number of ECS tasks"
}

variable "ecs_min_count" {
  type        = number
  description = "Minimum number of tasks for autoscaling"
}

variable "ecs_max_count" {
  type        = number
  description = "Maximum number of tasks for autoscaling"
}

variable "log_retention_in_days" {
  type        = number
  description = "CloudWatch log retention in days"
}

variable "flask_app" {
  type        = string
  description = "Flask app entrypoint module"
}

variable "flask_env" {
  type        = string
  description = "Flask environment mode"
}

variable "cpu_target_utilization" {
  type        = number
  description = "Target CPU utilization percentage for autoscaling"
}

variable "scale_in_cooldown" {
  type        = number
  description = "Scale in cooldown period in seconds"
}

variable "scale_out_cooldown" {
  type        = number
  description = "Scale out cooldown period in seconds"
}

# --- Frontend S3 & CloudFront ---
variable "frontend_bucket_name" {
  type        = string
  description = "S3 bucket name for frontend static assets"
}

variable "default_root_object" {
  type        = string
  description = "Default root object for CloudFront and SPA routing fallback"
}
