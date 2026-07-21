include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../terraform-modules/database"
}

dependency "networking" {
  config_path = "../networking"

  # Allows `terragrunt plan` to work even if networking hasn't been applied
  # yet in this session, using placeholder values. Real values are used
  # automatically once networking is actually applied.
  mock_outputs = {
    private_subnet_ids          = ["subnet-mock1", "subnet-mock2"]
    database_security_group_id  = "sg-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment                 = local.env_vars.locals.environment
  private_subnet_ids          = dependency.networking.outputs.private_subnet_ids
  database_security_group_id  = dependency.networking.outputs.database_security_group_id

  instance_class           = "db.t3.micro"
  multi_az                 = false
  deletion_protection      = false
  skip_final_snapshot      = true
  backup_retention_period  = 1
}
