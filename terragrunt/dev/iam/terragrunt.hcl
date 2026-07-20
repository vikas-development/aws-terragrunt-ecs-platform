include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../terraform-modules/iam"
}

dependency "database" {
  config_path = "../database"

  mock_outputs = {
    secret_arn = "arn:aws:secretsmanager:ap-south-1:000000000000:secret:mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment           = local.env_vars.locals.environment
  secrets_manager_arns  = [dependency.database.outputs.secret_arn]
}