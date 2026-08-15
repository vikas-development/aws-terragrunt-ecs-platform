# Environment Promotion Workflow

## Branch -> Environment Mapping

| Branch | Environment | Terragrunt folder | Apply behavior |
|---|---|---|---|
| `develop` | Dev | `terragrunt/dev/` | Auto-apply on merge (CI), or manual `terragrunt apply` |
| `qa` | QA | `terragrunt/qa/` | Auto-apply on merge, then QA test gate runs |
| `main` | Prod | `terragrunt/prod/` | Plan runs automatically, **apply requires manual approval** |

## Module Deployment Order (within any single environment)

```
networking -> iam -> ecr -> database -> ecs-service -> monitoring -> notifications
```

Destroy in the reverse order:

```
notifications -> monitoring -> ecs-service -> database -> networking
```

(`iam`, `ecr`, and `storage` are free/cheap - leave them running between sessions. Only
`networking`'s NAT Gateway, `database`'s RDS instance, and `ecs-service`'s ALB + Fargate
tasks cost meaningful money and should be destroyed after verification.)

## Isolation Verification

Run `scripts/verify-isolation.sh` after deploying networking + IAM in at least 2 environments
to confirm CIDR non-overlap, no VPC peering, IAM role separation, and secret separation.

## Environment-Specific Configuration Differences

| Setting | Dev | QA | Prod |
|---|---|---|---|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| NAT Gateway | Single (shared) | Single (shared) | One per AZ (HA) |
| RDS instance class | db.t3.micro | db.t3.micro | db.t3.small |
| RDS Multi-AZ | No | No | Yes |
| RDS deletion protection | No | No | Yes |
| RDS backup retention | 1 day | 1 day | 7 days |
| ECS task CPU/memory | 256/512 | 256/512 | 512/1024 |
| ECS desired count | 1 | 1 | 2 |
| CloudWatch CPU alarm threshold | 80% | 80% | 70% |
| S3 force_destroy | true | true | false |
