variable "prefix" {
  type        = string
  description = "Prefix for resource naming and tags (e.g. salma-realworld)"
}

variable "isolated_db_subnet_ids" {
  type        = list(string)
  description = "List of isolated database subnet IDs"
}

variable "rds_security_group_id" {
  type        = string
  description = "Security group ID for RDS allowing port 5432 from ECS"
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class (e.g. db.t3.micro)"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_username" {
  type        = string
  description = "Master database username"
}
