output "deployments_topic_arn" {
  value = aws_sns_topic.deployments.arn
}

output "alarms_topic_arn" {
  value = aws_sns_topic.alarms.arn
}
