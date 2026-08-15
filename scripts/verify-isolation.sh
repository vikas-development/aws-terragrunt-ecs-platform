#!/usr/bin/env bash
# scripts/verify-isolation.sh
echo "== Environment Isolation Verification =="
echo

echo "-- 1. Network isolation: non-overlapping VPC CIDRs --"
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=enterprise-deployment-platform" \
  --query "Vpcs[].{Env:Tags[?Key=='Name']|[0].Value,CIDR:CidrBlock,ID:VpcId}" \
  --output table
echo "Expect: dev=10.0.0.0/16, qa=10.1.0.0/16, prod=10.2.0.0/16, three distinct VPC IDs, zero overlap."
echo

echo "-- 2. No VPC peering between environments --"
aws ec2 describe-vpc-peering-connections \
  --filters "Name=tag:Project,Values=enterprise-deployment-platform" \
  --query "VpcPeeringConnections[].VpcPeeringConnectionId" \
  --output table
echo "Expect: empty."
echo

echo "-- 3. IAM role isolation --"
aws iam list-roles \
  --query "Roles[?contains(RoleName, 'enterprise-deployment-platform')].RoleName" \
  --output table
echo "Expect: 6 roles minimum (2 per env x 3 envs), each name-prefixed with its own environment."
echo

echo "-- 4. Secrets Manager isolation --"
aws secretsmanager list-secrets \
  --filters Key=name,Values=enterprise-deployment-platform \
  --query "SecretList[].Name" \
  --output table
echo "Expect: distinct dev/qa/prod-suffixed secret names."
echo

echo "== Done. =="
