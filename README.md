<p align="center">
  <img src="screenshots/production.png" width="500">
</p>

# Multi-Environment AWS Infrastructure using Terraform Workspaces

Designed and implemented a production-style AWS infrastructure using Terraform with environment isolation, private networking, remote state management, and reusable Infrastructure as Code.

## Demo

[Add your project demo link here]

---

##  Project Summary

This project provisions AWS infrastructure for **Development, Staging, and Production** environments using a single Terraform codebase and **Terraform Workspaces**.

Each workspace maintains a separate Terraform state and provides environment-specific configuration such as EC2 instance type, resource naming, and tags.

### Production Practices Applied

- Private EC2 instances with no public IP
- Public and private subnet architecture
- NAT Gateway for outbound internet access
- Internet Gateway for public subnet connectivity
- Dynamic Amazon Linux 2023 AMI lookup
- Remote Terraform state using Amazon S3
- Native S3 state locking
- Environment-specific EC2 instance sizing
- Consistent resource tagging

> In the current implementation, each workspace provisions its own complete infrastructure stack.

---

##  Key Skills Demonstrated

- Terraform Infrastructure as Code
- AWS VPC
- AWS Networking
- Public & Private Subnets
- Internet Gateway
- NAT Gateway
- Route Tables
- Amazon EC2
- Security Groups
- Amazon S3
- Terraform Remote State
- Terraform State Locking
- Terraform Workspaces
- Terraform Data Sources
- AWS CLI
- Multi-Environment Infrastructure

---

## Problem This Solves

Managing multiple environments manually can result in duplicated configurations, inconsistent infrastructure, state conflicts, and deployment errors.

This project solves these problems by using **Terraform Workspaces** to manage multiple environments from a single reusable Terraform configuration.

```text
                         Terraform Code
                               |
              +----------------+----------------+
              |                |                |
             DEV            STAGING            PROD
              |                |                |
        Separate State   Separate State   Separate State
              |                |                |
          AWS Stack        AWS Stack        AWS Stack
```
## Architecture

<p align="center">
  <img src="screenshots/architecture.png" width="1000">
</p>



##  Traffic Rules

- Public subnet → internet via IGW (direct)
- Private EC2 → internet via NAT (outbound only)
- Internet → private EC2 (blocked)
- SSH restricted to `allowed_ssh_cidr`

---

##  Environment Differences

|                | **dev**   | **staging**   | **prod**   |
| -------------- | --------- | ------------- | ---------- |
| EC2 size       | t2.micro  | t2.small      | t3.medium  |
| Resource names | `*-dev-*` | `*-staging-*` | `*-prod-*` |
| State file     | isolated  | isolated      | isolated   |

All environments share identical infrastructure definitions. The active workspace is the only variable controlling behaviour.

---

##  File Structure

```text
provider.tf                 AWS provider and version constraints
backend.tf                  S3 remote state with workspace namespacing
variables.tf                All input variables with types and validation
terraform.tfvars            Your actual values (gitignored)
terraform.tfvars.example    Safe template to copy and fill in
locals.tf                   Environment logic: name prefix, instance size, tags
data.tf                     Dynamic AMI lookup (latest Amazon Linux 2)
networking.tf               VPC, subnets, IGW, NAT Gateway, route tables
security.tf                 EC2 security group: SSH, VPC traffic, egress
compute.tf                  EC2 instance in private subnet
outputs.tf                  VPC ID, instance ID, private IP, NAT public IP
.gitignore                  Blocks state files, .terraform/, terraform.tfvars
```

---

##  File Reference

### `provider.tf`

Connects Terraform to AWS. Pins the provider to version 5.x to prevent breaking changes from automatic upgrades. Region is read from `var.region` and is never hardcoded.

Credentials are not stored here. Terraform reads them from `~/.aws/credentials`, environment variables, or an IAM role automatically.

---

### `backend.tf`

Stores state in S3 instead of locally. Each workspace gets its own isolated state file automatically:

```text
s3://multi-env-platform-terraform-state/
  env:/dev/terraform/terraform.tfstate
  env:/staging/terraform/terraform.tfstate
  env:/prod/terraform/terraform.tfstate
```

`use_lockfile = true` prevents two applies from running at the same time and corrupting state.

> The S3 bucket must be created manually before `terraform init` because Terraform cannot create its own backend.

---

### `variables.tf`

Defines every input the project accepts. All variables have types and descriptions. Sensitive ones have `validation` blocks that reject bad values before any AWS call is made.

| **Variable**          | **Default**                                    | **Purpose**                              |
| --------------------- | ---------------------------------------------- | ---------------------------------------- |
| `region`              | `us-east-1`                                    | AWS region for all resources             |
| `project_name`        | required                                       | Prefix on every resource name            |
| `owner`                | `""`                                           | Responsible team: applied as a tag       |
| `additional_tags`     | `{}`                                           | Extra tags merged into every resource    |
| `vpc_cidr`             | `10.0.0.0/16`                                  | VPC IP range                             |
| `public_subnet_cidr`  | `10.0.1.0/24`                                  | Public subnet IP range                   |
| `private_subnet_cidr` | `10.0.2.0/24`                                  | Private subnet IP range                  |
| `instance_type_map`   | dev=t2.micro, staging=t2.small, prod=t3.medium | EC2 size per environment                 |
| `ssh_key_name`        | `null`                                         | EC2 key pair name. `null` = SSM access only |
| `allowed_ssh_cidr`    | `0.0.0.0/0`                                    | IPs allowed to SSH. Use `x.x.x.x/32` in production |

**Validated variables:** `region`, `project_name`, `vpc_cidr`, `public_subnet_cidr`, `private_subnet_cidr`, `allowed_ssh_cidr`

---

### `terraform.tfvars`

Supplies actual values for variables. Terraform loads this automatically. Excluded from Git via `.gitignore` to prevent committing sensitive data.

Copy the example to get started:

```bash
cp terraform.tfvars.example terraform.tfvars
```

---

### `locals.tf`

Translates the active workspace into environment-specific values used across all resource files.

| **Local**       | **Value**                       | **Purpose**                     |
| --------------- | ------------------------------- | ------------------------------- |
| `env`           | `terraform.workspace`           | Active environment name         |
| `instance_type` | lookup from `instance_type_map` | Correct EC2 size for this env   |
| `name_prefix`   | `{project_name}-{env}`          | Prefix for every resource name  |
| `common_tags`   | merged tag map                  | Applied to every resource       |

---

### `data.tf`

Queries AWS at plan time for the latest Amazon Linux 2 AMI. This replaces a hardcoded AMI ID, which is region-specific and goes stale as AWS releases updated images.

Referenced in `compute.tf` as:

```text
data.aws_ami.amazon_linux.id
```

---

### `networking.tf`

Builds the full network topology in dependency order.

| **Resource**              | **Purpose**                                      |
| ------------------------- | ------------------------------------------------ |
| `aws_vpc`                 | Isolated private network: everything lives here |
| `aws_subnet public`       | Internet-facing tier: NAT Gateway lives here    |
| `aws_subnet private`      | Secure tier: EC2 lives here, no public IP       |
| `aws_internet_gateway`    | Connects public subnet to the internet           |
| `aws_eip`                 | Static public IP for the NAT Gateway             |
| `aws_nat_gateway`         | Outbound-only internet for private instances    |
| `aws_route_table public`  | Routes non-VPC traffic → IGW                     |
| `aws_route_table private` | Routes non-VPC traffic → NAT                     |

---

### `security.tf`

A stateful firewall attached to the EC2 instance. Stateful means response traffic is automatically allowed.

| **Rule** | **Port** | **Source**         | **Purpose**                        |
| -------- | -------- | ------------------ | ---------------------------------- |
| Ingress  | 22       | `allowed_ssh_cidr` | SSH access                         |
| Ingress  | all      | `vpc_cidr`         | Internal VPC communication         |
| Egress   | all      | `0.0.0.0/0`        | Outbound for updates and API calls |

---

### `compute.tf`

Deploys the EC2 app server into the private subnet.

- AMI resolved dynamically from `data.tf`: always current, always region-correct
- Instance size from `local.instance_type`: changes with the workspace
- No public IP: sits in private subnet
- `key_name = null` by default: use SSM Session Manager for access
- `gp3` volume: faster and cheaper than gp2, deleted on destroy

---

### `outputs.tf`

Values printed after `terraform apply` and stored in state.

| **Output**              | **Use**                                                              |
| ----------------------- | -------------------------------------------------------------------- |
| `environment`           | Confirms which workspace was deployed                                |
| `vpc_id`                | Reference from other Terraform projects                              |
| `public_subnet_id`      | For deploying load balancers or bastion hosts                        |
| `private_subnet_id`     | For deploying additional private resources                           |
| `ec2_instance_id`       | Connect via SSM: `aws ssm start-session --target <id>`               |
| `ec2_private_ip`        | Internal routing and DNS                                             |
| `nat_gateway_public_ip` | Whitelist in external firewalls and APIs                             |

---


## How to Use

### 1. Prerequisites

Make sure you have:

- AWS account
- AWS CLI installed and configured
- Terraform installed
- Git installed
- IAM permissions to create the required AWS resources

Verify the installations:

```bash
aws --version
terraform version
git --version

```

## S3 Backend Setup

# 1. Create S3 bucket
aws s3api create-bucket \
  --bucket general23buucket \
  --region us-east-1

<p align="center">
  <img src="screenshots/backend.png" width="500">
</p>


# 1. Initialize Terraform
terraform init

<p align="center">
  <img src="screenshots/init.png" width="1000">
</p>

# 2. Validate configuration
terraform validate

# 3. Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
<p align="center">
  <img src="screenshots/workspace.png" width="1000">
</p>

# 4. Select environment
terraform workspace select dev

# 5. Review changes
terraform plan

# 6. Apply infrastructure
terraform apply

# 4. Select environment
terraform workspace select staging
terraform plan
terraform apply

# 4. Select environment
terraform workspace select prod
terraform plan
terraform apply

##  Design Principles

- **Infrastructure as Code** — AWS infrastructure is defined and managed using Terraform.
- **Environment Isolation** — Dev, Staging, and Production use separate Terraform workspaces and state.
- **Reusable Configuration** — One Terraform codebase manages all environments.
- **Remote State Management** — Terraform state is stored securely in Amazon S3.
- **State Locking** — S3 lockfile prevents conflicting Terraform operations.
- **Private-by-Default** — EC2 instances are deployed in private subnets without public IPs.
- **Controlled Internet Access** — Private instances access the internet through a NAT Gateway.
- **Dynamic AMI Selection** — The latest matching Amazon Linux AMI is selected automatically.
- **Environment-Aware Resources** — Resource names and EC2 sizes are determined by the active workspace.
- **Consistent Tagging** — Common tags identify project and environment resources.
- **Reproducibility** — The same Terraform configuration can recreate each environment consistently.
