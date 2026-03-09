gitops-terraform-aks-eks-receipt-app/
├── terraform/
│   ├── eks/          ← AWS кластер, VPC, RDS
│   └── aks/          ← Azure кластер, VNet, PostgreSQL
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml           ← prod
│   ├── values-eks.yaml       ← AWS-специфичные overrides
│   └── values-aks.yaml       ← Azure-специфичные overrides
└── argocd/
    └── application.yaml