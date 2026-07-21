output "db_instance_id" {
  value = aws_db_instance.main.id
}

output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials — feed this into the IAM module's secrets_manager_arns input"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
