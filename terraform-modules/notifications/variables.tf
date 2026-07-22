variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alarm_email" {
  description = "Email address to subscribe to infra alarms and deployment notifications"
  type        = string
  default     = ""
}
