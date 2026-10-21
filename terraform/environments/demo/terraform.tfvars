# ==========================================
# Concrete Parameters: Demo Environment
# Zero hardcoded values in modules/variables.
# ==========================================

prefix      = "salma-realworld"
aws_region  = "us-east-1"
domain_name = "app.salmah.pp.ua"

# --- VPC & Networking ---
vpc_cidr = "10.0.0.0/16"

public_subnets = {
  "public-1a" = {
    cidr = "10.0.1.0/24"
    az   = "us-east-1a"
  }
  "public-1b" = {
    cidr = "10.0.2.0/24"
    az   = "us-east-1b"
  }
}

private_app_subnets = {
  "app-1a" = {
    cidr = "10.0.11.0/24"
    az   = "us-east-1a"
  }
  "app-1b" = {
    cidr = "10.0.12.0/24"
    az   = "us-east-1b"
  }
}

isolated_db_subnets = {
  "db-1a" = {
    cidr = "10.0.21.0/24"
    az   = "us-east-1a"
  }
  "db-1b" = {
    cidr = "10.0.22.0/24"
    az   = "us-east-1b"
  }
}

nat_gateway_subnet_key = "public-1a"
alb_ingress_ports      = [80, 443]
db_port                = 5432

# --- ALB ---
health_check_path = "/api/ping"
ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

# --- RDS PostgreSQL ---
db_name              = "realworlddb"
db_username          = "realworldadmin"
db_engine_version    = "16.15"
db_instance_class    = "db.t4g.micro"
db_allocated_storage = 20

# --- RDS Read Replica ---
enable_read_replica       = false # Step 1: Allow primary DB to activate automated backups first
replica_availability_zone = "us-east-1b"
backup_retention_period   = 1

# --- ECS Fargate Backend ---
container_image        = "253650698585.dkr.ecr.us-east-1.amazonaws.com/realworld-backend:latest"
container_port         = 8080
ecs_cpu                = "256"
ecs_memory             = "512"
ecs_desired_count      = 2
ecs_min_count          = 2
ecs_max_count          = 4
log_retention_in_days  = 7
flask_app              = "realworld.app"
flask_env              = "production"
cpu_target_utilization = 70.0
scale_in_cooldown      = 300
scale_out_cooldown     = 60

# --- Frontend S3 & CloudFront ---
frontend_bucket_name = "salma-realworld-frontend-253650698585"
default_root_object  = "index.html"
