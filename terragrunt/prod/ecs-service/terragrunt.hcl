include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../terraform-modules/ecs-service"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    vpc_id                       = "vpc-mock"
    public_subnet_ids            = ["subnet-mock1", "subnet-mock2"]
    private_subnet_ids           = ["subnet-mock3", "subnet-mock4"]
    alb_security_group_id        = "sg-mock1"
    ecs_tasks_security_group_id  = "sg-mock2"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "iam" {
  config_path = "../iam"
  mock_outputs = {
    ecs_execution_role_arn = "arn:aws:iam::000000000000:role/mock-execution"
    ecs_task_role_arn      = "arn:aws:iam::000000000000:role/mock-task"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "ecr" {
  config_path = "../ecr"
  mock_outputs = {
    repository_url = "000000000000.dkr.ecr.ap-south-1.amazonaws.com/mock-repo"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "database" {
  config_path = "../database"
  mock_outputs = {
    secret_arn = "arn:aws:secretsmanager:ap-south-1:000000000000:secret:mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment                  = local.env_vars.locals.environment
  vpc_id                       = dependency.networking.outputs.vpc_id
  public_subnet_ids            = dependency.networking.outputs.public_subnet_ids
  private_subnet_ids           = dependency.networking.outputs.private_subnet_ids
  alb_security_group_id        = dependency.networking.outputs.alb_security_group_id
  ecs_tasks_security_group_id  = dependency.networking.outputs.ecs_tasks_security_group_id

  ecs_execution_role_arn = dependency.iam.outputs.ecs_execution_role_arn
  ecs_task_role_arn      = dependency.iam.outputs.ecs_task_role_arn

  ecr_repository_url   = dependency.ecr.outputs.repository_url
  container_image_tag  = "v3"

  db_secret_arn = dependency.database.outputs.secret_arn

  task_cpu       = 512
  task_memory    = 1024
  desired_count  = 2
  min_capacity   = 2
  max_capacity   = 4
}
