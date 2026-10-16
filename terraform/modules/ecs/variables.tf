variable "prefix" {
  type        = string
  description = "Prefix for resource naming and tags (e.g. salma-realworld)"
}

variable "aws_region" {
  type        = string
  description = "AWS region for CloudWatch logging"
}

variable "container_image" {
  type        = string
  description = "ECR Docker image URI for the backend container"
}

variable "container_port" {
  type        = number
  description = "Port exposed by the backend container"
}

variable "cpu" {
  type        = string
  description = "Fargate task CPU units (e.g. 256 for 0.25 vCPU)"
}

variable "memory" {
  type        = string
  description = "Fargate task memory in MB (e.g. 512)"
}

variable "desired_count" {
  type        = number
  description = "Initial desired number of tasks to run"
}

variable "min_count" {
  type        = number
  description = "Minimum number of tasks for autoscaling"
}

variable "max_count" {
  type        = number
  description = "Maximum number of tasks for autoscaling"
}

variable "log_retention_in_days" {
  type        = number
  description = "CloudWatch log retention in days"
}

variable "private_app_subnet_ids" {
  type        = list(string)
  description = "Private application subnet IDs for ECS tasks"
}

variable "ecs_security_group_id" {
  type        = string
  description = "Security group ID for the ECS tasks"
}

variable "target_group_arn" {
  type        = string
  description = "Target group ARN from the ALB module"
}

variable "db_host" {
  type        = string
  description = "RDS PostgreSQL endpoint host"
}

variable "db_port" {
  type        = number
  description = "RDS PostgreSQL port"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_username" {
  type        = string
  description = "Master database username"
}

variable "db_password_secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret storing the database password"
}

variable "flask_app" {
  type        = string
  description = "Flask app entrypoint module (e.g. realworld.app)"
}

variable "flask_env" {
  type        = string
  description = "Flask environment mode (e.g. production)"
}

variable "cpu_target_utilization" {
  type        = number
  description = "Target CPU utilization percentage for autoscaling (e.g. 70.0)"
}

variable "scale_in_cooldown" {
  type        = number
  description = "Scale in cooldown period in seconds (e.g. 300)"
}

variable "scale_out_cooldown" {
  type        = number
  description = "Scale out cooldown period in seconds (e.g. 60)"
}
