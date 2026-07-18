# bootstrap/github-oidc.tf
#
# Creates the OIDC identity provider + IAM role that GitHub Actions assumes
# to deploy infra. No AWS access keys are ever stored in GitHub — the
# workflow exchanges a short-lived GitHub-issued token for temporary AWS
# credentials via this role.

variable "github_org" {
  description = "GitHub username or org that owns the repo"
  type        = string
  default     = "vikas-development"
}

variable "github_repo" {
  description = "GitHub repo name"
  type        = string
  default     = "aws-terragrunt-ecs-platform"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to specific branches -> maps 1:1 to dev/qa/prod deploy branches.
    # Wildcard covers PRs too, needed for `terragrunt plan` in CI checks.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/develop",
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/qa",
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_repo}:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "github-actions-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Purpose = "github-actions-oidc-deploy"
  }
}

# NOTE: This is intentionally broad (PowerUserAccess-style) to get moving in
# Phase 0. Phase 2 (IAM & Security Foundations) tightens this to a scoped,
# least-privilege policy covering only the services this project touches
# (VPC, ECS, RDS/DynamoDB, S3, IAM PassRole, CloudWatch, SNS, ECR).
resource "aws_iam_role_policy_attachment" "github_actions_deploy_temp" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}
