variable "environment" {
  description = "Environment name used for resource naming"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to ALB module resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where ALB and target group will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ALB"
  type        = list(string)
}

variable "target_group_port" {
  description = "Target group port for ECS task traffic"
  type        = number
}

variable "listener_port" {
  description = "Public ALB listener port"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check path for ALB target group"
  type        = string
  default     = "/health"
}
