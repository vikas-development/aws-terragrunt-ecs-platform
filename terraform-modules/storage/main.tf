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

resource "aws_s3_bucket" "app_assets" {
  bucket        = "${local.name_prefix}-app-assets"
  force_destroy = var.force_destroy

  tags = {
    Name = "${local.name_prefix}-app-assets"
  }
}

# Versioning — protects against accidental overwrite/delete of app assets
resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption at rest — non-negotiable baseline
resource "aws_s3_bucket_server_side_encryption_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block ALL public access — this bucket is for internal app assets, never
# meant to be browsable from the internet. If public assets are needed
# later (e.g. user uploads served via CDN), that's a separate bucket with
# its own deliberate policy, not a relaxation of this one.
resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket                  = aws_s3_bucket.app_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Explicit deny-non-TLS policy — belt and suspenders alongside public access
# block, ensures nothing can read/write over plain HTTP even from within
# the AWS account.
data "aws_iam_policy_document" "app_assets" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.app_assets.arn,
      "${aws_s3_bucket.app_assets.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  policy = data.aws_iam_policy_document.app_assets.json
}
