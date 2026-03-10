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
  # "https://" for trust policy
  oidc_issuer_host = replace(local.oidc_issuer_url, "https://", "")
}

# Скачиваем официальный IAM policy от AWS
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
    { name = "server.service.type", value = "ClusterIP" },
  ]

  depends_on = [
    kubernetes_namespace_v1.argocd,
    helm_release.aws_lb_controller,
  ]
}