# gitops-multicloud-aks-eks-receipt-app

Multi-cloud GitOps infrastructure for deploying [fullstack-microservices-ci-receipts](https://github.com/ascom/fullstack-microservices-ci-receipts) — a fullstack microservices application for receipt management.

## Overview

This repository provisions cloud infrastructure and manages application deployment using a GitOps approach:

- **Terraform** — provisions VPC/VNet, Kubernetes clusters (EKS on AWS, AKS on Azure), and supporting resources
- **ArgoCD** — continuous delivery; syncs application manifests from Git to the cluster
- **Helm** — packages application services with environment-specific value overrides

## Target Architecture

```
gitops-terraform-aks-eks-receipt-app/
├── infra/
│   ├── bootstrap/          # S3 remote state backend (AWS)
│   ├── modules/
│   │   ├── networking/     # VPC, subnets, NAT
│   │   └── eks/            # EKS cluster, node groups, IAM
│   └── live/
│       └── aws/dev/        # dev environment entrypoint
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml         # base values
│   ├── values-eks.yaml     # AWS overrides
│   └── values-aks.yaml     # Azure overrides
└── argocd/
    └── application.yaml    # ArgoCD Application manifest
```

## Cloud Targets

| Cloud | Cluster | Region |
|-------|---------|--------|
| AWS   | EKS     | eu-north-1 |
| Azure | AKS     | _(planned)_ |

## Status

> Work in progress. Bootstrap (S3 remote state) is provisioned. VPC, EKS, Helm, and ArgoCD layers are under active development.

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- `kubectl`
- `helm` >= 3
- ArgoCD CLI _(optional)_

## Getting Started

```bash
# 1. Bootstrap remote state (first time only)
cd infra/bootstrap
terraform init
terraform apply -var-file=backend.tfvars

# 2. Deploy dev environment
cd infra/live/aws/dev
terraform init -backend-config=backend.hcl
terraform apply -var-file=dev.tfvars
```
