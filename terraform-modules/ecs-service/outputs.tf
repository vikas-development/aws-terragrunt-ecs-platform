output "alb_dns_name" {
  description = "Public URL to hit the app - this is your entry point"
  value       = aws_lb.main.dns_name
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "alb_arn_suffix" {
  description = "Used by the monitoring module for CloudWatch metric dimensions"
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Used by the monitoring module for CloudWatch metric dimensions"
  value       = aws_lb_target_group.app.arn_suffix
}
