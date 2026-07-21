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

  mock_outputs = {
    vpc_id                      = "vpc-mock"
    private_subnet_ids          = ["subnet-mock1", "subnet-mock2"]
    database_security_group_id  = "sg-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment                 = local.env_vars.locals.environment
  vpc_id                      = dependency.networking.outputs.vpc_id
  private_subnet_ids          = dependency.networking.outputs.private_subnet_ids
  database_security_group_id  = dependency.networking.outputs.database_security_group_id

  instance_class           = "db.t3.small"  # slightly larger for Prod
  multi_az                 = true           # real HA for Prod
  deletion_protection      = true           # cannot be accidentally destroyed
  skip_final_snapshot      = false          # always snapshot before delete
  backup_retention_period  = 7
}
