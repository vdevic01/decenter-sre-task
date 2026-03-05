provider "aws" {
  region = "eu-central-1"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  access_key = "mock_access_key"
  secret_key = "mock_secret_key"

  default_tags {
    tags = {
      Owner       = "terraform"
      Environment = var.environment
      SRE_TASK    = "vlada_devic"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "alb" {
  source = "./alb_module"

  environment       = var.environment
  vpc_id            = data.aws_vpc.default.id
  subnet_ids        = data.aws_subnets.default.ids
  target_group_port = var.container_port
  listener_port     = 80
  health_check_path = "/health"
}

resource "aws_security_group" "ecs_service" {
  name        = "${var.environment}-ecs-service-sg"
  description = "Security group for ECS service tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "ecs" {
  source = "./ecs_module"

  environment          = var.environment
  image                = var.image
  container_name       = var.container_name
  container_port       = var.container_port
  desired_count        = var.desired_count
  subnet_ids           = data.aws_subnets.default.ids
  security_group_ids   = [aws_security_group.ecs_service.id]
  alb_target_group_arn = module.alb.target_group_arn

  depends_on = [module.alb]
}
