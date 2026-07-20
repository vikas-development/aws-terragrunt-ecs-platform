variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  description = "Public subnets — the ALB lives here"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets — ECS tasks live here, never directly internet-facing"
  type        = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "ecs_tasks_security_group_id" {
  type = string
}

variable "ecs_execution_role_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "container_image_tag" {
  description = "Image tag to deploy (e.g. v3, latest is discouraged since repo is IMMUTABLE)"
  type        = string
  default     = "latest"
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "task_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of tasks to keep running"
  type        = number
  default     = 1
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 2
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials, injected into the container as env vars"
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Plain (non-secret) environment variables for the container"
  type        = map(string)
  default     = {}
}
