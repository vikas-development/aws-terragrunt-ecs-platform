variable "project_name" {
  description = "Project name, used for resource naming/tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if it has objects in it. Handy for Dev/QA, dangerous for Prod."
  type        = bool
  default     = false
}
