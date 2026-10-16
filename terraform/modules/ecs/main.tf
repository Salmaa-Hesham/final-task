# ==========================================
# 1. ECS CLUSTER & CAPACITY PROVIDERS
# ==========================================
resource "aws_ecs_cluster" "main" {
  name = "${var.prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.prefix}-cluster"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 2
    weight            = 0
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
}

# ==========================================
# 2. CLOUDWATCH LOG GROUP
# ==========================================
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.prefix}-backend"
  retention_in_days = var.log_retention_in_days

  tags = {
    Name = "${var.prefix}-ecs-logs"
  }
}

# ==========================================
# 3. SSM PARAMETERS (Config Store)
# ==========================================
resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.prefix}/POSTGRES_HOST"
  type  = "String"
  value = var.db_host

  tags = {
    Name = "${var.prefix}-ssm-db-host"
  }
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${var.prefix}/POSTGRES_PORT"
  type  = "String"
  value = tostring(var.db_port)

  tags = {
    Name = "${var.prefix}-ssm-db-port"
  }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.prefix}/POSTGRES_DB"
  type  = "String"
  value = var.db_name

  tags = {
    Name = "${var.prefix}-ssm-db-name"
  }
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/${var.prefix}/POSTGRES_USER"
  type  = "String"
  value = var.db_username

  tags = {
    Name = "${var.prefix}-ssm-db-user"
  }
}

# ==========================================
# 4. TASK EXECUTION ROLE (ECR, Logs & Secrets)
# ==========================================
resource "aws_iam_role" "ecs_execution" {
  name = "${var.prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.prefix}-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Policy allowing Fargate Agent to fetch secrets from Secrets Manager & SSM
resource "aws_iam_role_policy" "ecs_secrets_access" {
  name = "${var.prefix}-ecs-secrets-policy"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [var.db_password_secret_arn]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters"
        ]
        Resource = [
          aws_ssm_parameter.db_host.arn,
          aws_ssm_parameter.db_port.arn,
          aws_ssm_parameter.db_name.arn,
          aws_ssm_parameter.db_user.arn
        ]
      }
    ]
  })
}

# ==========================================
# 5. TASK DEFINITION
# ==========================================
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.prefix}-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "${var.prefix}-backend"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]


      secrets = [
        for name, arn in {
          POSTGRES_PASSWORD = var.db_password_secret_arn
          POSTGRES_HOST     = aws_ssm_parameter.db_host.arn
          POSTGRES_PORT     = aws_ssm_parameter.db_port.arn
          POSTGRES_DB       = aws_ssm_parameter.db_name.arn
          POSTGRES_USER     = aws_ssm_parameter.db_user.arn
        } : { name = name, valueFrom = arn }
      ]

      environment = [
        { name = "FLASK_APP", value = var.flask_app },
        { name = "FLASK_ENV", value = var.flask_env },
        { name = "FLASK_RUN_PORT", value = tostring(var.container_port) }
      ]


      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.prefix}-backend-task"
  }
}

# ==========================================
# 6. ECS SERVICE
# ==========================================
resource "aws_ecs_service" "app" {
  name            = "${var.prefix}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 2
    weight            = 0
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.prefix}-backend"
    container_port   = var.container_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy.ecs_secrets_access
  ]

  tags = {
    Name = "${var.prefix}-backend-service"
  }
}

# ==========================================
# 7. AUTOSCALING (Min 2, Max 4 tasks)
# ==========================================
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_count
  min_capacity       = var.min_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.prefix}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_utilization
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}
