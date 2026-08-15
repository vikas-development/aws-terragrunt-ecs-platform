# terragrunt/root.hcl
#
# Included by every environment's terragrunt.hcl via `include "root"`.
# Defines the remote state backend and default AWS provider.
#
# NOTE: state_bucket_region and aws_region are deliberately separate.
# The state bucket physically lives in ap-south-1 (where bootstrap/ created
# it) and stays there. aws_region controls where actual resources
# (VPC, RDS, ECS, etc.) get deployed - these can differ.

locals {
  project_name = "enterprise-deployment-platform"

  # Where actual resources (VPC, RDS, ECS, ALB, etc.) get created.
  aws_region = "us-east-1"

  # Where the Terraform state S3 bucket + DynamoDB lock table physically
  # live. Do NOT change this unless you actually migrate/recreate the
  # bootstrap resources in a new region.
  state_bucket_region = "ap-south-1"

  state_bucket = "enterprise-deployment-platform-tfstate"
  lock_table   = "enterprise-deployment-platform-tfstate-lock"
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = local.state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.state_bucket_region
    dynamodb_table = local.lock_table
    encrypt        = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Project   = "${local.project_name}"
      ManagedBy = "terragrunt"
    }
  }
}
EOF
}

inputs = {
  project_name = local.project_name
  aws_region   = local.aws_region
}
