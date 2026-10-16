resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# 1. Public Subnets (For ALB)
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-${each.key}"
    Tier = "public"
  }
}

# 2. Private App Subnets (For ECS Backend)
resource "aws_subnet" "private_app" {
  for_each = var.private_app_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.prefix}-${each.key}"
    Tier = "private-app"
  }
}

# 3. Isolated DB Subnets (For RDS PostgreSQL)
resource "aws_subnet" "isolated_db" {
  for_each = var.isolated_db_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.prefix}-${each.key}"
    Tier = "isolated-db"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-gw"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[var.nat_gateway_subnet_key].id


  tags = {
    Name = "${var.prefix}-nat-gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.prefix}-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "${var.prefix}-private-app-rt"
  }
}
resource "aws_route_table_association" "private_app" {
  for_each       = var.private_app_subnets
  subnet_id      = aws_subnet.private_app[each.key].id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table" "isolated_db" {
  vpc_id = aws_vpc.vpc.id
  # No external routes! Keeps the database strictly isolated.
  tags = {
    Name = "${var.prefix}-isolated-db-rt"
  }
}
resource "aws_route_table_association" "isolated_db" {
  for_each       = var.isolated_db_subnets
  subnet_id      = aws_subnet.isolated_db[each.key].id
  route_table_id = aws_route_table.isolated_db.id
}


resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  # Dynamic ingress for ALB ports
  dynamic "ingress" {
    for_each = var.alb_ingress_ports
    content {
      description = "Allow port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.prefix}-alb-sg"
  }
}


resource "aws_security_group" "ecs_backend" {
  name        = "${var.prefix}-ecs-backend-sg"
  description = "Allow inbound from ALB only"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "Allow container port from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.prefix}-ecs-backend-sg"
  }
}


resource "aws_security_group" "rds" {
  name        = "${var.prefix}-rds-sg"
  description = "Allow inbound PostgreSQL from ECS only"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "Allow PostgreSQL from ECS backend"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-rds-sg"
  }
}