include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../terraform-modules/monitoring"
}

dependency "ecs_service" {
  config_path = "../ecs-service"
  mock_outputs = {
    cluster_name             = "mock-cluster"
    service_name             = "mock-service"
    alb_arn_suffix            = "app/mock-alb/0000000000000000"
    target_group_arn_suffix   = "targetgroup/mock-tg/0000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "database" {
  config_path = "../database"
  mock_outputs = {
    db_instance_id = ""
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "notifications" {
  config_path = "../notifications"
  mock_outputs = {
    alarms_topic_arn = "arn:aws:sns:ap-south-1:000000000000:mock-topic"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment              = local.env_vars.locals.environment
  ecs_cluster_name         = dependency.ecs_service.outputs.cluster_name
  ecs_service_name         = dependency.ecs_service.outputs.service_name
  alb_arn_suffix           = dependency.ecs_service.outputs.alb_arn_suffix
  target_group_arn_suffix  = dependency.ecs_service.outputs.target_group_arn_suffix
  db_instance_id           = dependency.database.outputs.db_instance_id
  cpu_alarm_threshold      = 80
  sns_topic_arn            = dependency.notifications.outputs.alarms_topic_arn
}
