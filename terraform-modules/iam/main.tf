terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Trust policy - both roles are assumed by the ECS tasks service, not by
# anything else. Nobody outside ECS can assume these.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------
# EXECUTION ROLE — used by the ECS agent itself (not your app code) to:
#   - pull the container image from ECR
#   - write container logs to CloudWatch
#   - read secrets/SSM params needed to inject as environment variables
# This is infrastructure plumbing, not your application's permissions.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "ecs_execution" {
  name               = "${local.name_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = {
    Name = "${local.name_prefix}-ecs-execution-role"
  }
}

# AWS-managed policy covering exactly the ECR pull + CloudWatch Logs write
# permissions execution roles need. This is the standard, narrowly-scoped
# policy AWS provides for this exact purpose.
resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Execution role also needs to read secrets/SSM params to inject them into
# the container at startup (via task definition secrets block). Only
# attached if secret ARNs are actually provided.
data "aws_iam_policy_document" "ecs_execution_secrets" {
  count = length(var.secrets_manager_arns) > 0 || length(var.ssm_parameter_arns) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = length(var.secrets_manager_arns) > 0 ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = var.secrets_manager_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.ssm_parameter_arns) > 0 ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["ssm:GetParameters", "ssm:GetParameter"]
      resources = var.ssm_parameter_arns
    }
  }
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  count  = length(var.secrets_manager_arns) > 0 || length(var.ssm_parameter_arns) > 0 ? 1 : 0
  name   = "${local.name_prefix}-ecs-execution-secrets"
  role   = aws_iam_role.ecs_execution.id
  policy = data.aws_iam_policy_document.ecs_execution_secrets[0].json
}

# ---------------------------------------------------------------------------
# TASK ROLE — used by YOUR APPLICATION CODE at runtime (e.g. if the app
# itself needs to call S3, DynamoDB, etc). Starts completely empty —
# permissions get added here as later phases (database, storage) wire in
# real AWS service access. Never attach broad managed policies here.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task" {
  name               = "${local.name_prefix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = {
    Name = "${local.name_prefix}-ecs-task-role"
  }
}

# CloudWatch custom metrics / logs from within the app itself (not the ECS
# agent's own logging, which the execution role already covers). Minimal
# and safe to include by default.
data "aws_iam_policy_document" "ecs_task_baseline" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_task_baseline" {
  name   = "${local.name_prefix}-ecs-task-baseline"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.ecs_task_baseline.json
}
