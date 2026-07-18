# bootstrap/main.tf
#
# ONE-TIME SETUP. Run this manually (terraform init && terraform apply) BEFORE
# any Terragrunt environment is deployed. This creates the S3 bucket + DynamoDB
# table that ALL environments (dev, qa, prod) use for remote state + locking.
#
# This is intentionally plain Terraform, not Terragrunt — it has no backend
# of its own (chicken-and-egg problem), so its state stays local. Run once,
# commit the resulting bucket/table names into terragrunt/root.hcl, and forget
# about this folder unless you're tearing the whole project down.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region for the state backend"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used to prefix backend resources"
  type        = string
  default     = "enterprise-deployment-platform"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-tfstate"

  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    Project   = var.project_name
    ManagedBy = "bootstrap-terraform"
    Purpose   = "terraform-remote-state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "bootstrap-terraform"
    Purpose   = "terraform-state-locking"
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  value = aws_dynamodb_table.terraform_locks.id
}
