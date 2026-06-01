# AWS Infrastructure Automation Platform

Production-style Infrastructure as Code (IaC) platform built with Terraform, AWS, Jenkins, Docker, and ECS.

This project automates the deployment, management, and destruction of complete AWS environments through a CI/CD-driven workflow. The platform provisions secure networking, compute resources, DNS, VPN connectivity, certificate management, and deployment pipelines while maintaining full environment isolation and reproducibility.

The architecture currently supports multiple environments (PROD, TEST, and DEVL), with additional environments created dynamically through dedicated Terraform variable files.

## Key Features

* Infrastructure as Code (Terraform)
* Multi-environment deployment strategy
* Automated CI/CD pipelines using Jenkins
* AWS ECS Fargate container deployment
* Route 53 private DNS integration
* AWS Client VPN with split tunneling
* Fully automated PKI and certificate lifecycle management
* Bastion host with AWS Systems Manager (SSM)
* Secure private/public subnet architecture
* Automated infrastructure provisioning and teardown
* Environment-specific IAM access controls
* Cloud-native deployment and operations model

## CI/CD Pipeline Architecture

The platform is deployed through a three-stage Jenkins pipeline.

### 1. Bootstrap Stage

Creates the IAM foundation required for environment deployments.

Responsibilities:

* Provision IAM users and groups per environment
* Apply least-privilege access policies
* Separate deployment permissions by role
* Generate deployment identities used by subsequent pipeline stages

### 2. Infrastructure Stage

Deploys and manages AWS resources using Terraform.

Capabilities:

* Provision complete AWS environments
* Deploy VPCs, subnets, route tables, EC2 instances, security groups, Route 53 records, and VPN resources
* Enable or disable Client VPN deployments
* Configure automated EC2 scheduling through CloudWatch
* Create AMI backups before resource destruction
* Manage environment-specific network access controls
* Support full environment creation and teardown

### 3. Application Deployment Stage

Deploys containerized workloads through Docker and ECS.

Responsibilities:

* Build Docker images
* Push images to Amazon ECR
* Deploy workloads to ECS Fargate
* Maintain consistent deployment workflows across environments
* Support automated application delivery through CI/CD

## Architecture Overview

The platform follows a secure hub-and-spoke design:

* Public subnet hosting a Bastion Host
* Private subnet hosting isolated workloads
* Route 53 Private Hosted Zone for internal service discovery
* AWS Client VPN for secure remote access
* AWS Systems Manager (SSM) for administrative access
* ECS Fargate for containerized services
* Jenkins running in Docker for deployment automation

## Security Design

Security is implemented as a core design principle:

* Private workloads have no direct internet exposure
* Bastion access is managed through AWS Systems Manager
* IAM permissions follow least-privilege principles
* VPN authentication uses Terraform-generated certificates
* Internal resources are discoverable through private DNS only
* Split-tunnel VPN minimizes unnecessary traffic routing

## Automated Certificate Management

The entire PKI lifecycle is managed through Terraform.

This includes:

* Certificate Authority (CA) generation
* Server certificate creation
* Per-user client certificates
* Automatic ACM certificate imports
* Automated certificate cleanup during infrastructure destruction

No manual certificate generation or ACM administration is required.

## Future Enhancements

Planned improvements include:

* Application Load Balancer integration
* Route 53 public DNS for ECS services
* HTTPS termination with ACM
* Monitoring and observability enhancements
* Auto-scaling policies for ECS workloads

## Project Outcome

This project demonstrates practical DevOps engineering skills across cloud infrastructure, automation, networking, security, CI/CD, container orchestration, and Infrastructure as Code.

The entire environment can be provisioned, modified, or destroyed through a single automated workflow, providing a repeatable and production-ready deployment platform on AWS.
