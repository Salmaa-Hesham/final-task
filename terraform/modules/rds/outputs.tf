output "db_host" {
  description = "The database hostname (address) without port (needed by ECS POSTGRES_HOST)"
  value       = aws_db_instance.db.address
}

output "db_port" {
  description = "The database port (needed by ECS POSTGRES_PORT)"
  value       = aws_db_instance.db.port
}

output "db_endpoint" {
  description = "The database connection endpoint (host:port)"
  value       = aws_db_instance.db.endpoint
}

output "db_name" {
  description = "The database name"
  value       = aws_db_instance.db.db_name
}

output "db_username" {
  description = "The master username"
  value       = aws_db_instance.db.username
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.db.id
}

output "db_password_secret_arn" {
  description = "The ARN of the Secrets Manager secret storing the database password"
  value       = aws_secretsmanager_secret.db_password.arn
}
