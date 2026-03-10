# gitops-multicloud-aks-eks-receipt-app

Multi-cloud GitOps infrastructure for deploying a fullstack microservices receipt management application on AWS EKS (and Azure AKS — planned).

## Stack

| Tool | Role |
|---|---|
| **Terraform** | Provisions VPC, subnets, IAM, EKS cluster and node groups |
| **ArgoCD** | Continuous delivery — syncs Helm charts from Git to the cluster |
| **Helm** | Packages application services with per-environment value overrides |

## Repository structure

```
infra/
├── live/
│   └── aws/
│       ├── bootstrap/          # S3 backend + DynamoDB lock (apply once)
│       └── dev/
│           ├── dev.tfvars      # shared variables for all dev layers
│           ├── aws-network/    # VPC, subnets, IGW, NAT GW, route tables
│           ├── aws-iam/        # EKS cluster role + node group role
│           ├── aws-eks/        # EKS cluster + managed node group (Ubuntu 22.04)
│           └── aws-addons/     # (planned) AWS LB Controller, ExternalDNS
└── modules/
    └── aws/
        ├── vpc/
        ├── subnets/
        ├── igw/
        ├── nat_gw/
        ├── routetable/
        └── eks/                # EKS cluster + launch template + node group
```

## Cloud targets

| Cloud | Cluster | Region | Status |
|---|---|---|---|
| AWS | EKS 1.32 | eu-north-1 | 🟡 ready to apply |
| Azure | AKS | — | 📋 planned |

## Infrastructure layers (AWS dev)

### 1. bootstrap
Creates S3 bucket for Terraform remote state. Apply once per account.

### 2. aws-network ✅ deployed
- VPC `10.0.0.0/16`
- 2 public subnets (eu-north-1a/b) — tagged `kubernetes.io/role/elb`
- 2 private subnets (eu-north-1a/b) — tagged `kubernetes.io/role/internal-elb`
- Internet Gateway, NAT Gateway (in public subnet az1)
- Public and private route tables with associations

### 3. aws-iam ✅ deployed
- `ascom-receipts-eks-cluster-role` — for EKS control plane
- `ascom-receipts-eks-node-group-role` — for worker nodes (AmazonEKSWorkerNodePolicy + AmazonEKS_CNI_Policy + AmazonEC2ContainerRegistryReadOnly)

### 4. aws-eks 🟡 ready to apply
- EKS 1.32 cluster with private + public endpoint
- Managed node group in private subnets
- Ubuntu 22.04 Jammy (Canonical EKS-optimised AMI, `t3.small`, gp3 20 GiB, IMDSv2)
- Reads IAM role ARNs from `aws-iam` remote state
- Discovers subnets from `aws-network` via `kubernetes.io` tags

### 5. aws-addons 📋 planned
- AWS Load Balancer Controller (Helm)
- ExternalDNS (Helm)

## EKS node group defaults (`dev.tfvars`)

| Parameter | Value |
|---|---|
| Kubernetes version | 1.32 |
| Node AMI | Ubuntu 22.04 Jammy (Canonical) |
| Instance type | t3.small |
| Root disk | 20 GiB gp3 |
| Desired / Min / Max nodes | 2 / 1 / 3 |

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured (`aws configure`)
- `kubectl`
- `helm` >= 3

## Deploy

Each layer has its own state and is applied independently.

```bash
# 1. Bootstrap (first time only)
cd infra/live/aws/bootstrap
terraform init
terraform apply -var-file=backend.tfvars

# 2. Network
cd infra/live/aws/dev/aws-network
terraform init
terraform apply -var-file=../dev.tfvars

# 3. IAM
cd infra/live/aws/dev/aws-iam
terraform init
terraform apply -var-file=../dev.tfvars

# 4. EKS
cd infra/live/aws/dev/aws-eks
terraform init
terraform apply -var-file=../dev.tfvars

# 5. Configure kubectl
aws eks update-kubeconfig \
  --region eu-north-1 \
  --name ascom-receipts-eks
```
