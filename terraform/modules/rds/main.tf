# ==========================================
# 1. RANDOM PASSWORD & SECRETS MANAGER
# ==========================================
resource "random_password" "db_password" {
  length  = 16
  special = false # Alphanumeric ensures 100% compatibility with SQLAlchemy connection URLs
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.prefix}/db-password"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.prefix}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# ==========================================
# 2. DB SUBNET GROUP (Spans 2 Isolated Subnets)
# ==========================================
resource "aws_db_subnet_group" "db" {
  name        = "${var.prefix}-db-subnet-group"
  description = "Database subnet group for ${var.prefix} PostgreSQL"
  subnet_ids  = var.isolated_db_subnet_ids

  tags = {
    Name = "${var.prefix}-db-subnet-group"
  }
}

# ==========================================
# 3. RDS POSTGRESQL INSTANCE
# ==========================================
resource "aws_db_instance" "db" {
  identifier        = "${var.prefix}-postgres"
  engine            = "postgres"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result # Automatically populated from random_password!

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false

  backup_retention_period = var.enable_read_replica ? max(var.backup_retention_period, 1) : var.backup_retention_period

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.prefix}-postgres"
  }
}

# ==========================================
# 4. RDS READ REPLICA
# ==========================================
resource "aws_db_instance" "replica" {
  count = var.enable_read_replica ? 1 : 0

  identifier             = "${var.prefix}-postgres-replica"
  replicate_source_db    = aws_db_instance.db.identifier
  instance_class         = var.replica_instance_class != null ? var.replica_instance_class : var.instance_class
  storage_type           = "gp3"
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = {
    Name = "${var.prefix}-postgres-replica"
  }
}
