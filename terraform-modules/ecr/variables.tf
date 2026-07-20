variable "project_name" {
  description = "Project name, used for resource naming/tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "max_image_count" {
  description = "Max number of images to retain before old ones are auto-expired"
  type        = number
  default     = 10
}
