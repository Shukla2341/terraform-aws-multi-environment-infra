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
