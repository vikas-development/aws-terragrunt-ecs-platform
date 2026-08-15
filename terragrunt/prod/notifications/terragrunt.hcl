include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../terraform-modules/notifications"
}

inputs = {
  environment = local.env_vars.locals.environment
  alarm_email = "vk3331101@gmail.com" # <-- CHANGE THIS to your real email
}
