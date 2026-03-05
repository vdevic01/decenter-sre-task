variable "environment" {
  description = "The environment for the resources"
  type        = string
}

variable "image" {
  description = "Container image URI for ECS task"
  type        = string
}

variable "container_name" {
  description = "Container name for ECS task"
  type        = string
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Container port exposed by ECS task"
  type        = number
  default     = 3000
}
