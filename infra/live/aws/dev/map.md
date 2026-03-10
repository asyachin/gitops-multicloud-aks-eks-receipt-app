aws-network/   ← сейчас здесь
  VPC, Subnets, IGW, NAT GW, Route Tables
  + теги kubernetes.io на подсетях  

aws-iam/       ← следующий шаг
  IAM Roles для EKS, Node Group, LB Controller

aws-eks/       ← после IAM
  EKS Cluster, Node Group
  → автоматически создаст: SG, ENI, endpoint
  
aws-addons/    ← после кластера
  AWS LB Controller (Helm) → создаст ALB/NLB по запросу
  ExternalDNS (Helm) → создаст Route53 записи