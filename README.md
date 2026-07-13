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
- [ ] Initialize Git repository and branch strategy (`main`, `develop`, feature branches)
- [ ] Define folder structure: `terraform-modules/`, `terragrunt/`, `app/`, `docker/`, `.github/workflows/`
- [ ] Set up remote Terraform state backend (S3 + DynamoDB lock table)
- [ ] Configure AWS credentials via GitHub Actions OIDC (no long-lived access keys)
- [ ] Write root `terragrunt.hcl` with common inputs (region, tags, backend config)

### Phase 1 — Networking Module
- [ ] VPC with public/private subnets across 2 AZs
- [ ] NAT Gateway (or NAT instance for cost control in Dev)
- [ ] Route tables, Internet Gateway
- [ ] Security groups (baseline deny-by-default)
- [ ] Environment-specific CIDR isolation (Dev vs Prod)

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

## Repository Structure

```
enterprise-deployment-platform/
├── terraform-modules/
│   ├── networking/
│   ├── ecs-service/
│   ├── database/
│   ├── storage/
│   ├── iam/
│   ├── monitoring/
│   └── notifications/
├── terragrunt/
│   ├── dev/
│   ├── qa/
│   └── prod/
├── app/
│   └── src/
├── tests/
│   ├── unit/
│   ├── terratest/
│   └── smoke/
├── docker/
├── .github/
│   └── workflows/
├── scripts/
├── docs/
└── README.md
```

---

## Status

🟡 **Phase 0 in progress** — repo scaffolding underway (Dev, QA, Prod environment folders created).
