#!/usr/bin/env bash
# scripts/destroy-env.sh
# Usage: ./scripts/destroy-env.sh dev|qa|prod
set -euo pipefail

ENV="${1:-}"

if [[ -z "$ENV" ]]; then
  echo "Usage: $0 <dev|qa|prod>"
  exit 1
fi

if [[ "$ENV" != "dev" && "$ENV" != "qa" && "$ENV" != "prod" ]]; then
  echo "Invalid environment: $ENV (expected dev, qa, or prod)"
  exit 1
fi

if [[ "$ENV" == "prod" ]]; then
  read -rp "You are about to DESTROY PROD infra. Type 'destroy-prod' to confirm: " CONFIRM
  if [[ "$CONFIRM" != "destroy-prod" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

cd "$(dirname "$0")/../terragrunt/$ENV"
terragrunt run-all destroy
