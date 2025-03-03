module "controller_iam_role_with_eks_oidc" {
  source  = "terraform-aws-modules/iam/aws//wrappers/iam-role-for-service-accounts-eks"
  version = "5.52.2"

  defaults = {
    create_role = true
  }
  items = {
    vpc-cni = {
      role_name                      = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "vpc-cni")
      role_description               = "iam role for vpc-cni irsa"
      tags                           = { Name = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "vpc-cni") }
      attach_vpc_cni_policy          = true
      vpc_cni_enable_cloudwatch_logs = false
      vpc_cni_enable_ipv4            = true
      vpc_cni_enable_ipv6            = false
      oidc_providers = {
        eks_20250220 = {
          provider_arn               = module.eks.oidc_provider_arn
          namespace_service_accounts = ["kube-system:aws-node"]
        }
      }
    }
  }
}