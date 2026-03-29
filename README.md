# Multi-Cloud GitOps — AWS EKS + Azure AKS

> GitOps-driven infrastructure for a full-stack web application across multiple cloud providers.  
> AWS EKS is live. Azure AKS integration and Karmada-based multi-cluster federation are in active development.



---

## What this project demonstrates

- **Infrastructure as Code** — full AWS stack (VPC → IAM → EKS → add-ons) and Azure AKS provisioned with Terraform, using reusable modules and layered remote state
- **GitOps** — Argo CD App of Apps pattern with sync-wave ordering; Git is the single source of truth for cluster state
- **Production-grade security** — Sealed Secrets (encrypted secrets in Git), IRSA for all add-ons (no static credentials), ACM TLS, Let's Encrypt via cert-manager
- **Full observability** — Prometheus + Grafana + Alertmanager + Loki + Grafana Alloy, all deployed from Git
- **Multi-cloud networking** — AWS VPC and Azure VNet provisioned with the same module pattern, ready for cross-cloud connectivity
- **Planned: Karmada federation** — unified control plane over EKS + AKS with a single entry point and inter-cloud load balancing

---

## Architecture

```
                        ┌─────────────────────────────────────────────────┐
                        │              Git Repository (dev branch)        │
                        │         app/  ←→  Argo CD watches this         │
                        └──────────────────────┬──────────────────────────┘
                                               │ GitOps sync
              ┌────────────────────────────────┼────────────────────────────┐
              │                                │                            │
              ▼                                ▼                            ▼
  ┌───────────────────────┐      ┌─────────────────────────┐   ┌──────────────────────┐
  │    AWS EKS (live)     │      │  Karmada Control Plane  │   │   Azure AKS (planned)│
  │  eu-north-1           │◄─────│  (planned)              │──►│                      │
  │                       │      │  • PropagationPolicy    │   │                      │
  │  • Django backend     │      │  • single ingress point │   │  • same workloads    │
  │  • React/Nginx front  │      │  • cross-cloud LB       │   │  • AKS node pool     │
  │  • PostgreSQL         │      └─────────────────────────┘   │  • Azure CNI / VNet  │
  │  • EFS media storage  │                                     └──────────────────────┘
  └───────────────────────┘
        │
        ├── AWS ALB (TLS, Route53)
        ├── cert-manager (Let's Encrypt)
        ├── Sealed Secrets
        ├── kube-prometheus-stack
        └── Loki + Grafana Alloy
```

**Planned multi-cluster flow (Karmada):**  
A Karmada control plane will federate EKS and AKS clusters, distributing workloads via `PropagationPolicy` and exposing a single global entry point. Traffic will be balanced across cloud providers, enabling active-active multi-cloud deployments with failover.

---

## Tech stack

| Layer | Tool | Purpose |
|---|---|---|
| IaC | **Terraform** | VPC/VNet, IAM, EKS, AKS, add-ons, ACM certs, Ingresses |
| GitOps | **Argo CD** | App of Apps, sync-wave ordering, auto-sync + self-heal |
| Multi-cluster | **Karmada** | Federation, PropagationPolicy, global load balancing *(planned)* |
| Secrets | **Sealed Secrets** | Encrypted secrets safe to commit to Git |
| Ingress | **AWS LB Controller** | ALB/NLB from Kubernetes Ingress annotations |
| DNS | **ExternalDNS** | Automatic Route53 record management |
| Storage | **EBS CSI / EFS CSI** | gp3 block volumes + shared `ReadWriteMany` media storage |
| TLS | **cert-manager** | Let's Encrypt via DNS-01 challenge (Route53) |
| Observability | **kube-prometheus-stack** | Prometheus, Grafana, Alertmanager |
| Logging | **Loki + Grafana Alloy** | Structured log aggregation from all pods |
| Auth (IRSA) | **OIDC / IAM** | Fine-grained AWS permissions per service account |
| App | **Django + React/Nginx** | Full-stack recipe/receipt web application |
| DB | **PostgreSQL 17** | In-cluster StatefulSet with gp3 PVC |

---

## Repository structure

```
.
├── app/                              # GitOps manifests — Argo CD source of truth
│   ├── apps/
│   │   ├── application.yaml          # Root App of Apps (apply once to bootstrap)
│   │   ├── sealed-secrets.yaml       # sync-wave 1
│   │   ├── storage.yaml              # sync-wave 1 — gp3 StorageClass
│   │   ├── cert-manager.yaml         # sync-wave 2
│   │   ├── loki.yaml                 # sync-wave 2
│   │   ├── monitoring.yaml           # sync-wave 2 — kube-prometheus-stack
│   │   ├── alloy.yaml                # sync-wave 3
│   │   ├── cert-manager-config.yaml  # sync-wave 3 — ClusterIssuer
│   │   ├── monitoring-config.yaml    # sync-wave 3 — Grafana credentials
│   │   └── receipts.yaml             # sync-wave 4 — application last
│   ├── receipts/
│   │   ├── backend/                  # Django API (port 9000)
│   │   ├── frontend/                 # Nginx + React (port 80)
│   │   ├── postgres/                 # StatefulSet + headless Service
│   │   └── sealed-secrets/           # DB credentials + app env (kubeseal encrypted)
│   ├── cert-manager/                 # ClusterIssuer (Let's Encrypt production)
│   ├── monitoring/                   # Grafana SealedSecret
│   └── storage/                      # gp3 StorageClass
│
└── infra/
    ├── modules/
    │   ├── aws/                      # Reusable: vpc, subnets, igw, nat_gw, routetable, eks
    │   └── azure/                    # Reusable: vnet, aks
    └── live/
        ├── aws/
        │   ├── bootstrap/            # S3 remote state + DynamoDB lock
        │   └── dev/
        │       ├── aws-network/      # VPC, subnets, IGW, NAT, routes
        │       ├── aws-iam/          # EKS cluster + node group IAM roles
        │       ├── aws-eks/          # EKS cluster, node group, OIDC
        │       └── aws-addons/       # LB Controller, ExternalDNS, CSI drivers,
        │                             # cert-manager, Argo CD, ACM, Ingresses, EFS
        └── azure/
            ├── bootstrap/            # Azure remote state backend
            └── dev/
                ├── az-network/       # VNet, subnets
                └── aks/              # AKS cluster
```

---

## Cloud targets

| Cloud | Cluster | Region | Status |
|---|---|---|---|
| AWS | EKS 1.32 | eu-north-1 | ✅ Live |
| Azure | AKS | — | 🔧 In progress |
| Multi-cluster | Karmada federation | — | 📋 Planned |

---

## Infrastructure layers (AWS)

Terraform is applied in sequential layers; each layer reads outputs of the previous one from remote state.

```
bootstrap   →   aws-network   →   aws-iam   →   aws-eks   →   aws-addons
(S3/DynoDB)     (VPC/subnets)     (IAM roles)   (cluster)     (everything else)
```

**aws-addons** provisions IRSA roles for every add-on (no static AWS credentials in-cluster), EFS + PVCs for shared media, ACM certificates with automatic DNS validation, Kubernetes Ingresses (keeping ACM ARNs out of Git), and bootstraps Argo CD via Helm.

### EKS node group

| Parameter | Value |
|---|---|
| Kubernetes | 1.32 |
| Instance | t3.medium |
| AMI | Ubuntu 22.04 (Canonical EKS-optimised) |
| Root disk | 30 GiB gp3 |
| Nodes | 2 desired / 1 min / 3 max |

---

## Deployment

### Prerequisites

- Terraform ≥ 1.5
- AWS CLI configured
- `kubectl`, `helm` ≥ 3, `kubeseal`

### 1. Provision infrastructure

```bash
cd infra/live/aws/bootstrap   && terraform init && terraform apply -var-file=backend.tfvars
cd ../dev/aws-network          && terraform init && terraform apply -var-file=../dev.tfvars
cd ../aws-iam                  && terraform init && terraform apply -var-file=../dev.tfvars
cd ../aws-eks                  && terraform init && terraform apply -var-file=../dev.tfvars
cd ../aws-addons               && terraform init && terraform apply -var-file=../dev.tfvars
```

### 2. Configure kubeconfig

```bash
aws eks update-kubeconfig --region eu-north-1 --name ascom-receipts-eks
```

### 3. Bootstrap GitOps

```bash
# Push manifests, then apply the root app once — Argo CD takes over from here
git push origin dev
kubectl apply -f app/apps/application.yaml
```

Argo CD will sync all child applications automatically in sync-wave order.

### Monitor

```bash
kubectl get applications -n argocd
kubectl get pods -n receipts -w
```

---

## Roadmap

- [x] AWS EKS cluster with full add-on stack
- [x] Argo CD App of Apps with sync-wave ordering
- [x] Sealed Secrets, IRSA, cert-manager, ExternalDNS
- [x] Prometheus + Grafana + Loki observability
- [x] Azure AKS Terraform modules
- [ ] Azure AKS cluster deployed and application mirrored
- [ ] Karmada control plane installed on a management cluster
- [ ] `PropagationPolicy` distributing receipts workload to both EKS and AKS
- [ ] Single global Ingress / load balancer entry point across clouds
- [ ] Active-active multi-cloud traffic splitting with failover

---

## Related repositories

| Repository | Purpose |
|---|---|
| [`fullstack-microservices-ci-reciepts`](https://github.com/asyachin/fullstack-microservices-ci-reciepts) | CI pipeline — GitHub Actions builds Docker images and pushes to Docker Hub |

---

## License

[MIT](LICENSE)
