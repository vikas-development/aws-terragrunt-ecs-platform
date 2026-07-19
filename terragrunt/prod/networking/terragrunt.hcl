include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../terraform-modules/networking"
}

inputs = {
  environment           = local.env_vars.locals.environment
  vpc_cidr              = local.env_vars.locals.vpc_cidr
  availability_zones    = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs   = ["10.2.1.0/24", "10.2.2.0/24"]
  private_subnet_cidrs  = ["10.2.101.0/24", "10.2.102.0/24"]
  enable_nat_gateway    = true
  single_nat_gateway    = false  # Prod gets one NAT per AZ for real HA
}
