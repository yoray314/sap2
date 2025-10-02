# SAP2 - Basic AWS Web Application Stack (Terraform)

## THIS IS UNSECURE DEPLOYMENT DO NOT REPRODUCE UNLESS YOU KNOW ABOUT IT.

This repository provisions a simple 3-tier style stack using Terraform on AWS:

- Application Load Balancer (public)
- Web server (Amazon Linux 2) in an Auto Scaling Group (size 1)
- PostgreSQL (Amazon RDS)

All resources are isolated inside a dedicated VPC with public subnets for ALB & web, and private subnets for the database.

## Architecture

```
Internet
   |
 [ALB]
   |
[ASG: Web EC2]
   |
  (Security Group restricts 5432)
   |
 [RDS Postgres]
```

## Components

| Layer | Service | Notes |
|-------|---------|-------|
| Load Balancer | AWS ALB | Listens on HTTP 80 |
| Web Tier | EC2 (ASG size 1) | Simple Python http.server serving dynamic page with DB info |
| Database | RDS PostgreSQL | Single AZ, no backups (for demo), password randomly generated |

## Prerequisites

- AWS account & credentials configured (e.g. via `aws configure` or environment variables)
- Terraform >= 1.6
- An SSH key pair locally (public key path for web instance access)

## Quick Start

1. Clone repo & enter terraform directory:
```
cd terraform
```
2. Provide variables (recommended: create `terraform.tfvars`):
```
public_key_path = "~/.ssh/id_rsa.pub"
allowed_ip      = "YOUR_IP/32"   # tighten from 0.0.0.0/0
region          = "eu-central-1"  # default; override if needed
```
3. Initialize & apply:
```
terraform init
terraform apply -auto-approve
```
4. After apply, outputs show ALB DNS:
```
terraform output alb_dns_name
```
Open that DNS in a browser; you should see the demo page.

## Variable Overview

See `variables.tf` for defaults. Sensitive values (DB password) are generated automatically and available in state & as a sensitive output.

## Clean Up

Destroy all resources when done to avoid charges:
```
terraform destroy -auto-approve
```

## Security Notes

- Demo only: wide-open security groups for HTTP & SSH (adjust in real use).
- DB backups disabled for cost/simplicity.
- No HTTPS termination (can add ACM cert + redirect later).

## Extending

Potential improvements:
- Add ACM certificate & HTTPS listener
- Add CloudWatch alarms & logs
- Parameter Store / Secrets Manager for DB creds
- Use container service (ECS/Fargate) instead of raw EC2
- Add Ansible for post-provision config beyond user data

## Repository Structure

```
terraform/
  providers.tf
  variables.tf
  network.tf
  security.tf
  compute.tf
  database.tf
  outputs.tf
  templates/
    web_user_data.sh.tpl
```

`task.md` tracks assignment requirements.

## Managing Infrastructure

Standard Terraform workflow:
- Modify .tf files
- `terraform plan` to review changes
- `terraform apply` to deploy
- `terraform destroy` to remove

## Troubleshooting
- If ALB health checks fail, check instance security groups & user data service.
- Use AWS Console or `aws ec2 describe-instances` to inspect instance.

---

This satisfies the assignment core: automated provisioning of load balancer, web server, and database as separate components.
