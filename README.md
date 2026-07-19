# Enterprise Multi-Environment Deployment Platform

A cloud-native DevOps automation platform that provisions and manages complete application environments (Dev, Prod) on AWS using Infrastructure as Code, with security scanning and centralized monitoring built in from day one.

> **Scope note:** This build targets **Dev + QA + Prod** environments to keep every module fully working end-to-end rather than partially implemented across many environments. A Staging environment can be added later by reusing the same Terragrunt pattern.

---

## Core Technologies

| Category | Tool |
|---|---|
| Cloud Provider | AWS |
| IaC | Terraform + Terragrunt |
| Containerization | Docker |
| Container Platform | Amazon ECS (AWS Fargate) |
| Networking | Amazon VPC |
| Storage | Amazon S3 |
| Database | Amazon RDS / DynamoDB |
| IAM | AWS IAM (least privilege) |
| Monitoring | Amazon CloudWatch (primary) |
| Notifications | Amazon SNS |
| CI/CD | GitHub Actions |
| Security Scanning | Trivy |
| OS / Automation | Linux, Bash |

---

## Architecture Principles

- **Modular Terraform modules** — networking, ECS service, database, storage, IAM, monitoring, notifications — each independently reusable.
- **Terragrunt** orchestrates modules per environment, keeping environment configs DRY.
- **Security-first, not bolted-on** — least-privilege IAM per environment, no hardcoded secrets (AWS Secrets Manager / SSM Parameter Store), network segmentation between environments, container image scanning before deploy.
- **Serverless containers** — ECS Fargate, no EC2 or Kubernetes cluster management.
- **Cost control** — every environment must be destroyable via a single script (`scripts/destroy-env.sh`) to avoid idle AWS spend between work sessions.

---

## Project Phases

### Phase 0 — Repository & Foundation Setup
- [x] Initialize Git repository
- [x] Define folder structure: `terraform-modules/`, `terragrunt/`, `app/`, `docker/`, `.github/workflows/`, `bootstrap/`, `tests/`
- [x] Branch strategy: `develop` → Dev, `qa` → QA, `main` → Prod (Prod applies gated by manual approval)
- [x] Remote Terraform state backend (S3 + DynamoDB lock table) — `bootstrap/main.tf`, run once manually
- [x] GitHub Actions OIDC role for AWS auth (no long-lived access keys) — `bootstrap/github-oidc.tf`
- [x] Root `terragrunt/root.hcl` with shared backend + provider config
- [x] Per-environment `env.hcl` files (`terragrunt/dev`, `terragrunt/qa`, `terragrunt/prod`)
- [x] Cost-safety teardown script — `scripts/destroy-env.sh`
- [x] CI validation workflow scaffold — `.github/workflows/terragrunt-validate.yml`

### Phase 1 — Networking Module
- [x] VPC with public/private subnets across 2 AZs
- [x] NAT Gateway (single shared in Dev/QA for cost control, one-per-AZ in Prod for HA)
- [x] Route tables, Internet Gateway
- [x] Security groups (baseline deny-by-default: ALB → ECS tasks → Database only)
- [x] Environment-specific CIDR isolation (Dev `10.0.0.0/16`, QA `10.1.0.0/16`, Prod `10.2.0.0/16`)

### Phase 2 — IAM & Security Foundations
- [ ] Least-privilege IAM roles per service (ECS task role, execution role, CI/CD deploy role)
- [ ] IAM policies scoped per environment (no cross-env access)
- [ ] Secrets management via AWS Secrets Manager / SSM Parameter Store
- [ ] S3 bucket policies (block public access, encryption at rest)

### Phase 3 — Storage & Database Modules
- [ ] S3 module (app assets, Terraform state, logs)
- [ ] RDS module (or DynamoDB, depending on app) with encryption, automated backups
- [ ] Subnet groups placed in private subnets only
- [ ] Environment-specific instance sizing (small in Dev, right-sized in Prod)

### Phase 4 — Application Containerization
- [ ] Write sample application (or use existing app) with health check endpoint
- [ ] Dockerfile (multi-stage build, minimal base image)
- [ ] Local docker build + run validation
- [ ] Push to Amazon ECR

### Phase 5 — ECS Fargate Deployment Module
- [ ] ECS cluster module
- [ ] Task definition (CPU/memory, environment variables from SSM)
- [ ] ECS service with Application Load Balancer
- [ ] Auto-scaling policy (target tracking on CPU/requests)

### Phase 6 — CI/CD Pipeline (GitHub Actions)
- [ ] Workflow: lint & validate Terraform/Terragrunt (`terraform fmt`, `validate`, `tflint`)
- [ ] Workflow: build Docker image
- [ ] Workflow: **Trivy vulnerability scan** (fail pipeline on HIGH/CRITICAL)
- [ ] Workflow: push image to ECR
- [ ] Workflow: `terragrunt plan` on PR, `terragrunt apply` on merge to `main`
- [ ] Workflow: deploy new task definition revision to ECS

### Phase 7 — Monitoring & Observability
- [ ] CloudWatch dashboards (ECS service metrics, ALB metrics, RDS metrics)
- [ ] CloudWatch alarms (high CPU, unhealthy targets, 5xx errors)
- [ ] CloudWatch Logs for ECS tasks
- [ ] *(Optional extension)* Prometheus + Grafana for custom app-level metrics

### Phase 8 — Notifications
- [ ] SNS topic for deployment events
- [ ] SNS topic for infrastructure alarm events
- [ ] Email/Slack subscription integration
- [ ] Wire CloudWatch alarms → SNS

### Phase 9 — Multi-Environment Validation
- [ ] Deploy full stack to Dev
- [ ] Deploy full stack to QA (used to run the full QA/testing gate from Phase 10 before Prod promotion)
- [ ] Deploy full stack to Prod (separate AWS account or strict IAM boundary recommended)
- [ ] Validate environment isolation (network, IAM, data) across Dev, QA, Prod
- [ ] Document environment promotion workflow (Dev → QA → Prod)

### Phase 10 — Quality Assurance & Testing
- [ ] **Static/IaC validation**: `terraform fmt -check`, `terraform validate`, `tflint` on every module
- [ ] **IaC security scanning**: `checkov` or `tfsec` against Terraform modules (misconfigurations, public S3, open SGs, unencrypted resources)
- [ ] **Container scanning**: Trivy scan gate already in CI (Phase 6) — document severity thresholds and exceptions process
- [ ] **Unit tests** for app code (`app/src`) — basic test suite with coverage threshold
- [ ] **Terraform module tests** using Terratest (or `terraform plan` diff checks) to validate module outputs before merge
- [ ] **Integration/smoke tests** post-deploy to QA: health check endpoint returns 200, ALB target group healthy, ECS service stable count matches desired count
- [ ] **Environment isolation tests**: confirm Dev/QA IAM roles cannot access Prod resources, confirm network segmentation (no route between VPCs)
- [ ] **Load/basic performance test** (e.g. simple `k6` or `hey` script) against QA before promoting to Prod
- [ ] **Rollback test**: verify ECS service rolls back cleanly to previous task definition on failed health check
- [ ] Document QA gates required to pass before `terragrunt apply` to Prod (all of the above green in CI)

### Phase 11 — Documentation & Portfolio Polish
- [ ] Architecture diagram (VPC, ECS, RDS, CI/CD flow)
- [ ] `docs/runbook.md` — how to deploy, destroy, and troubleshoot
- [ ] `docs/qa-strategy.md` — full QA approach, tools, and gates (expanded from Phase 10)
- [ ] Cost breakdown per environment
- [ ] Convert to portfolio writeup / PPTX (matching your existing project format)

---

## Branch Strategy → Environment Mapping

| Branch | Environment | Terragrunt folder | Apply behavior |
|---|---|---|---|
| `develop` | Dev | `terragrunt/dev/` | Auto-apply on merge |
| `qa` | QA | `terragrunt/qa/` | Auto-apply on merge, then Phase 10 QA gate runs |
| `main` | Prod | `terragrunt/prod/` | Plan on merge, **manual approval required** before apply (GitHub Environment protection rule) |

Promotion flow: feature branch → PR into `develop` → PR into `qa` → PR into `main`.

---

## Repository Structure

```
enterprise-deployment-platform/
├── bootstrap/                  # one-time: state backend + OIDC role (plain terraform, run manually)
│   ├── main.tf
│   └── github-oidc.tf
├── terraform-modules/
│   ├── networking/
│   ├── ecs-service/
│   ├── database/
│   ├── storage/
│   ├── iam/
│   ├── monitoring/
│   └── notifications/
├── terragrunt/
│   ├── root.hcl                # shared backend + provider config
│   ├── dev/
│   │   └── env.hcl
│   ├── qa/
│   │   └── env.hcl
│   └── prod/
│       └── env.hcl
├── app/
│   └── src/
├── tests/
│   ├── unit/
│   ├── terratest/
│   └── smoke/
├── docker/
├── .github/
│   └── workflows/
│       └── terragrunt-validate.yml
├── scripts/
│   └── destroy-env.sh
├── docs/
└── README.md
```

---

## Status

✅ **Phase 0 complete** — repo scaffolding, remote state backend, GitHub OIDC role, root Terragrunt config, Dev/QA/Prod env files, CI validation passing on all three branches, and branch protection on `main` are all in place.

✅ **Phase 1 complete** — `terraform-modules/networking/` built and verified live in all 3 environments (Dev `10.0.0.0/16`, QA `10.1.0.0/16`, Prod `10.2.0.0/16`), confirmed via `aws ec2 describe-vpcs`. QA and Prod destroyed after verification to control cost; Dev kept running for continued development.

🟡 **Phase 2 next** — IAM & Security Foundations (least-privilege roles, Secrets Manager, S3 bucket policies).
