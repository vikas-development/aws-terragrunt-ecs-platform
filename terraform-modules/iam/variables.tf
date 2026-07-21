variable "project_name" {
  description = "Project name, used for resource naming/tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager secret ARNs the ECS task is allowed to read. Leave empty until Phase 3/4 create actual secrets."
  type        = list(string)
  default     = []
}

variable "ssm_parameter_arns" {
  description = "List of SSM Parameter Store ARNs the ECS task is allowed to read. Leave empty until needed."
  type        = list(string)
  default     = []
}
