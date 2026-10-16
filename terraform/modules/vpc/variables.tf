variable "prefix" {
  type        = string
  description = "Prefix for resource naming and tags (e.g. salma-realworld)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Map of public subnets with CIDR and AZ"
}

variable "private_app_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Map of private app subnets with CIDR and AZ"
}

variable "isolated_db_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Map of isolated database subnets with CIDR and AZ"
}

variable "nat_gateway_subnet_key" {
  type        = string
  description = "Key of the public subnet where the NAT Gateway is deployed (e.g. public-subnet-1)"
}

variable "alb_ingress_ports" {
  type        = list(number)
  description = "List of ports allowed for ALB ingress (e.g. [80, 443])"
}

variable "container_port" {
  type        = number
  description = "Port exposed by the backend container (e.g. 8080)"
}

variable "db_port" {
  type        = number
  description = "Port exposed by the database (e.g. 5432)"
}
