# terragrunt/root.hcl
#
# Included by every environment's terragrunt.hcl via `include "root"`.
# Defines the remote state backend and default AWS provider — kept in ONE
# place so dev/qa/prod never drift on backend config.

locals {
  project_name = "enterprise-deployment-platform"
  aws_region   = "ap-south-1"

  # Filled in after running `bootstrap/` once — see bootstrap/main.tf outputs.
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
    region         = local.aws_region
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
