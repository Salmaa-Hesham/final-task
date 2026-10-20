# ==========================================
# 1. NETWORKING (VPC, Subnets, NAT GW, SGs)
# ==========================================
module "vpc" {
  source = "../../modules/vpc"

  prefix                 = var.prefix
  vpc_cidr               = var.vpc_cidr
  public_subnets         = var.public_subnets
  private_app_subnets    = var.private_app_subnets
  isolated_db_subnets    = var.isolated_db_subnets
  nat_gateway_subnet_key = var.nat_gateway_subnet_key
  alb_ingress_ports      = var.alb_ingress_ports
  container_port         = var.container_port
  db_port                = var.db_port
}

# ==========================================
# 2. DNS & SSL (Route 53 & Wildcard ACM)
# ==========================================
module "route53_acm" {
  source = "../../modules/route53_acm"

  prefix      = var.prefix
  domain_name = var.domain_name
}

# ==========================================
# 3. APPLICATION LOAD BALANCER (ALB)
# ==========================================
module "alb" {
  source = "../../modules/alb"

  prefix                = var.prefix
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.vpc.alb_security_group_id
  certificate_arn       = module.route53_acm.certificate_arn
  container_port        = var.container_port
  health_check_path     = var.health_check_path
  ssl_policy            = var.ssl_policy
}

# ==========================================
# 4. DATABASE (RDS PostgreSQL)
# ==========================================
module "rds" {
  source = "../../modules/rds"

  prefix                  = var.prefix
  isolated_db_subnet_ids  = module.vpc.isolated_db_subnet_ids
  rds_security_group_id   = module.vpc.rds_security_group_id
  db_name                 = var.db_name
  db_username             = var.db_username
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  enable_read_replica     = var.enable_read_replica
  replica_instance_class  = var.replica_instance_class
  backup_retention_period = var.backup_retention_period
}

# ==========================================
# 5. CONTAINER SERVICE (ECS Fargate Backend)
# ==========================================
module "ecs" {
  source = "../../modules/ecs"

  prefix                 = var.prefix
  aws_region             = var.aws_region
  container_image        = var.container_image
  container_port         = var.container_port
  cpu                    = var.ecs_cpu
  memory                 = var.ecs_memory
  desired_count          = var.ecs_desired_count
  min_count              = var.ecs_min_count
  max_count              = var.ecs_max_count
  log_retention_in_days  = var.log_retention_in_days
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  ecs_security_group_id  = module.vpc.ecs_security_group_id
  target_group_arn       = module.alb.target_group_arn
  db_host                = module.rds.db_host
  db_port                = module.rds.db_port
  db_name                = module.rds.db_name
  db_username            = module.rds.db_username
  db_password_secret_arn = module.rds.db_password_secret_arn
  flask_app              = var.flask_app
  flask_env              = var.flask_env
  cpu_target_utilization = var.cpu_target_utilization
  scale_in_cooldown      = var.scale_in_cooldown
  scale_out_cooldown     = var.scale_out_cooldown
}

# ==========================================
# 6. STATIC FRONTEND (S3 + CloudFront CDN)
# ==========================================
module "frontend_s3_cloudfront" {
  source = "../../modules/frontend_s3_cloudfront"

  prefix              = var.prefix
  bucket_name         = var.frontend_bucket_name
  domain_name         = var.domain_name
  certificate_arn     = module.route53_acm.certificate_arn
  default_root_object = var.default_root_object
}

# ==========================================
# 7. ROUTE 53 DNS ALIAS RECORDS
# ==========================================
# Backend API: api.app.salmah.pp.ua -> ALB
resource "aws_route53_record" "api" {
  zone_id         = module.route53_acm.zone_id
  name            = "api.${var.domain_name}"
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

# Frontend SPA: app.salmah.pp.ua -> CloudFront
resource "aws_route53_record" "frontend" {
  zone_id         = module.route53_acm.zone_id
  name            = var.domain_name
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = module.frontend_s3_cloudfront.cloudfront_domain_name
    zone_id                = module.frontend_s3_cloudfront.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
