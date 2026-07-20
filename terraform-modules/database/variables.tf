variable "project_name" {
  description = "Project name, used for resource naming/tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the networking module"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs from the networking module (RDS lives here, never in a public subnet)"
  type        = list(string)
}

variable "database_security_group_id" {
  description = "Security group ID from the networking module (already scoped to only accept traffic from ECS tasks)"
  type        = string
}

variable "instance_class" {
  description = "RDS instance size"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage in GB"
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.14"
}

variable "database_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "appadmin"
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability. Costs roughly 2x — enable in Prod only."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevent accidental deletion. Should be true in Prod, false in Dev/QA for easy teardown."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on delete. true = fast/cheap teardown for Dev/QA, false = safe for Prod."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Days to retain automated backups"
  type        = number
  default     = 1
}
