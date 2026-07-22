terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_sns_topic" "deployments" {
  name = "${local.name_prefix}-deployments"
  tags = { Name = "${local.name_prefix}-deployments" }
}

resource "aws_sns_topic" "alarms" {
  name = "${local.name_prefix}-alarms"
  tags = { Name = "${local.name_prefix}-alarms" }
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_sns_topic_subscription" "deployment_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.deployments.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
