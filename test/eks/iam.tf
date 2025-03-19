module "iam_assumable_role_eks" {
  source  = "terraform-aws-modules/iam/aws//wrappers/iam-assumable-role"
  version = "5.52.2"

  defaults = {
    create_role = true
  }
  items = {
    eks_node_ec2 = {
      role_name         = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "eks-node-ec2")
      role_description  = "iam role for eks ec2 node"
      role_requires_mfa = false
      tags              = { Name = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "eks-node-ec2") }
      # ec2 instance profile
      create_instance_profile = true
      # permission policy
      inline_policy_statements = []
      custom_role_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      ]
      # trust policy
      create_custom_role_trust_policy = false
      custom_role_trust_policy        = ""
      trusted_role_services           = ["ec2.amazonaws.com"]
      trust_policy_conditions         = []
      trusted_role_actions            = []
      trusted_role_arns               = []
    }
  }
}

module "iam_role_with_eks_oidc_system" {
  source  = "terraform-aws-modules/iam/aws//wrappers/iam-role-for-service-accounts-eks"
  version = "5.52.2"

  defaults = {
    create_role = true
  }
  items = {
    vpc_cni = {
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
    aws_efs_csi = {
      role_name             = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "aws-efs-csi")
      role_description      = "iam role for aws-efs-csi irsa"
      tags                  = { Name = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "aws-efs-csi") }
      attach_efs_csi_policy = true
      oidc_providers = {
        eks_20250220 = {
          provider_arn               = module.eks.oidc_provider_arn
          namespace_service_accounts = ["kube-system:efs-csi-controller-sa", "kube-system:efs-csi-node-sa"]
        }
      }
    }
  }
}