data "aws_region" "current" {}

locals {
  tags = merge({ Environment = var.environment }, var.tags)
}

resource "aws_ecs_cluster" "this" {
  name = "${var.environment}-ecs-cluster"

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.environment}/${var.container_name}"
  retention_in_days = var.log_retention_in_days

  tags = local.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.environment}-${var.container_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        for env_name, env_value in merge(var.container_environment, {
          APP_ENV = var.environment
          HOST    = "0.0.0.0"
          PORT    = tostring(var.container_port)
          }) : {
          name  = env_name
          value = env_value
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = var.container_name
        }
      }
    }
  ])

  tags = local.tags
}

resource "aws_ecs_service" "this" {
  name            = "${var.environment}-${var.container_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]

  tags = local.tags
}
