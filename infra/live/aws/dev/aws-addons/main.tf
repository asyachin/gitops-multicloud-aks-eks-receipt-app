# =============================================================================
# REMOTE STATE — read OIDC provider outputs from the aws-eks layer
# =============================================================================

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "ascom-receipts-app-tfstate-319393fe"
    key    = "gitops-terraform-aks-eks-receipt-app/dev/aws-eks/terraform.tfstate"
    region = "eu-north-1"
  }
}

locals {
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_issuer_url   = data.terraform_remote_state.eks.outputs.oidc_issuer_url
  # Strip "https://" prefix — required for OIDC condition keys in IAM trust policies
  oidc_issuer_host = replace(local.oidc_issuer_url, "https://", "")
}

# =============================================================================
# AWS LOAD BALANCER CONTROLLER
# Provisions ALB/NLB resources in response to Kubernetes Ingress/Service objects.
# Uses IRSA to authenticate against AWS APIs without static credentials.
# =============================================================================

# Fetch the official IAM policy document maintained by the upstream project
data "http" "lb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "lb_controller" {
  name   = "${var.cluster_name}-lb-controller-policy"
  policy = data.http.lb_controller_policy.response_body
}

resource "aws_iam_role" "lb_controller" {
  name = "${var.cluster_name}-lb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_host}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${local.oidc_issuer_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

# =============================================================================
# EXTERNAL DNS
# Automatically creates and updates Route53 DNS records based on
# Ingress/Service annotations (external-dns.alpha.kubernetes.io/hostname).
# =============================================================================

resource "aws_iam_role" "external_dns" {
  name = "${var.cluster_name}-external-dns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_host}:sub" = "system:serviceaccount:kube-system:external-dns"
          "${local.oidc_issuer_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "external_dns" {
  name = "${var.cluster_name}-external-dns-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = ["arn:aws:route53:::hostedzone/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones", "route53:ListResourceRecordSets"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

# =============================================================================
# EBS CSI DRIVER
# Enables dynamic provisioning of EBS volumes as PersistentVolumes (gp2/gp3).
# Required for stateful workloads such as Prometheus and Loki.
# =============================================================================

resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${local.oidc_issuer_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [aws_iam_role_policy_attachment.ebs_csi]
}

# =============================================================================
# CERT-MANAGER
# Automates TLS certificate issuance and renewal via Let's Encrypt.
# Uses DNS-01 challenge against Route53 to validate domain ownership,
# which supports wildcard certificates and works without public HTTP endpoints.
# =============================================================================

resource "aws_iam_role" "cert_manager" {
  name = "${var.cluster_name}-cert-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_host}:sub" = "system:serviceaccount:cert-manager:cert-manager"
          "${local.oidc_issuer_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "cert_manager" {
  name = "${var.cluster_name}-cert-manager-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Required to poll the status of DNS propagation during challenge
        Effect   = "Allow"
        Action   = ["route53:GetChange"]
        Resource = ["arn:aws:route53:::change/*"]
      },
      {
        # Required to create/delete TXT records for DNS-01 challenge
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = ["arn:aws:route53:::hostedzone/*"]
      },
      {
        # Required to discover the hosted zone ID by domain name
        Effect   = "Allow"
        Action   = ["route53:ListHostedZonesByName"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager.arn
}

# =============================================================================
# HELM RELEASES
# =============================================================================

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.2"
  namespace  = "kube-system"

  set = [
    { name = "clusterName",                                               value = var.cluster_name },
    { name = "serviceAccount.create",                                     value = "true" },
    { name = "serviceAccount.name",                                       value = "aws-load-balancer-controller" },
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = aws_iam_role.lb_controller.arn },
    { name = "region",                                                    value = var.region },
    { name = "vpcId",                                                     value = var.vpc_id },
  ]

  depends_on = [aws_iam_role_policy_attachment.lb_controller]
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.14.4"
  namespace  = "kube-system"

  set = [
    { name = "provider",                                                   value = "aws" },
    { name = "aws.region",                                                 value = var.region },
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = aws_iam_role.external_dns.arn },
    { name = "domainFilters[0]",                                           value = var.domain_name },
    { name = "txtOwnerId",                                                 value = var.cluster_name },
  ]

  depends_on = [aws_iam_role_policy_attachment.external_dns]
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.18"
  namespace  = "argocd"

  set = [
    # Use ClusterIP — access is provided via ALB Ingress, not a direct LoadBalancer
    { name = "server.service.type", value = "ClusterIP" },
  ]

  depends_on = [
    kubernetes_namespace_v1.argocd,
    helm_release.aws_lb_controller,
  ]
}
