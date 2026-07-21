variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix (e.g. app/edp-dev-alb/xxxx) - used for CloudWatch metric dimensions"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix - used for CloudWatch metric dimensions"
  type        = string
}

variable "db_instance_id" {
  description = "RDS instance identifier for DB metrics. Leave empty if database isn't deployed."
  type        = string
  default     = ""
}

variable "cpu_alarm_threshold" {
  type    = number
  default = 80
}

variable "sns_topic_arn" {
  description = "SNS topic to notify on alarm. Leave empty until Phase 8 wires SNS - alarms still work without notification."
  type        = string
  default     = ""
}
