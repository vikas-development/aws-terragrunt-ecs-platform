include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../terraform-modules/storage"
}

inputs = {
  environment   = local.env_vars.locals.environment
  force_destroy = true  # Dev: allow easy teardown even with objects in bucket
}
