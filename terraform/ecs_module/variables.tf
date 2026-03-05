variable "environment" {
  description = "Environment name used for resource naming and tags"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to ECS module resources"
  type        = map(string)
  default     = {}
}

variable "cpu" {
  description = "Task CPU units for ECS Fargate task definition"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Task memory (MiB) for ECS Fargate task definition"
  type        = string
  default     = "512"
}

variable "image" {
  description = "Container image URI"
  type        = string
}

variable "container_name" {
  description = "Container name used in task definition"
  type        = string
}

variable "desired_count" {
  description = "Desired number of running ECS tasks"
  type        = number
  default     = 3
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS service network configuration"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for ECS service network configuration"
  type        = list(string)
}

variable "log_retention_in_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14
}

variable "task_role_arn" {
  description = "IAM role ARN for the ECS task role"
  type        = string
  default     = null
}

variable "container_environment" {
  description = "Environment variables passed to container"
  type        = map(string)
  default     = {}
}

variable "container_port" {
  description = "Container port exposed by the ECS task"
  type        = number
  default     = 3000
}

variable "alb_target_group_arn" {
  description = "ALB target group ARN for ECS service registration"
  type        = string
}
