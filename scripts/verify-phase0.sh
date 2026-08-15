#!/usr/bin/env bash
# scripts/verify-phase0.sh
set -uo pipefail
echo "== Phase 0 Verification =="
echo

echo "-- Folder structure --"
for d in bootstrap terraform-modules terragrunt/dev terragrunt/qa terragrunt/prod app docker .github/workflows scripts docs; do
  if [ -d "$d" ]; then echo "OK: $d"; else echo "MISSING: $d"; fi
done
echo

echo "-- AWS live resources --"
if command -v aws >/dev/null 2>&1; then
  aws s3api head-bucket --bucket enterprise-deployment-platform-tfstate 2>/dev/null \
    && echo "OK: S3 state bucket exists" || echo "MISSING: S3 state bucket"
  aws dynamodb describe-table --table-name enterprise-deployment-platform-tfstate-lock >/dev/null 2>&1 \
    && echo "OK: DynamoDB lock table exists" || echo "MISSING: DynamoDB lock table"
  aws iam get-role --role-name github-actions-deploy-role >/dev/null 2>&1 \
    && echo "OK: github-actions-deploy-role exists" || echo "MISSING: github-actions-deploy-role"
else
  echo "AWS CLI not found - skipping live checks"
fi

echo
echo "== Done. =="
