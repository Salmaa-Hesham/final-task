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

variable "enable_read_replica" {
  type        = bool
  default     = false
  description = "Whether to create a read replica for the RDS database"
}

variable "replica_instance_class" {
  type        = string
  default     = null
  description = "Instance class for the read replica (defaults to instance_class if null)"
}

variable "backup_retention_period" {
  type        = number
  default     = 1
  description = "Backup retention period in days (must be >= 1 for read replica creation)"
}

variable "replica_availability_zone" {
  type        = string
  default     = null
  description = "Availability zone for the read replica (e.g. us-east-1b)"
}
