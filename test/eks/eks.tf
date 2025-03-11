module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  # eks cluster config
  create                                     = true
  create_kms_key                             = false
  cluster_encryption_config                  = {}
  enable_auto_mode_custom_tags               = false
  cluster_name                               = format("%s-%s-%s-eks", local.corp, local.environment, local.product)
  enable_cluster_creator_admin_permissions   = true
  enable_irsa                                = true
  enable_security_groups_for_pods            = false
  create_cluster_primary_security_group_tags = false
  cluster_version                            = "1.32"
  authentication_mode                        = "API"
  bootstrap_self_managed_addons              = false
  cluster_endpoint_private_access            = true
  cluster_endpoint_public_access             = true
  cluster_ip_family                          = "ipv4"
  cluster_service_ipv4_cidr                  = "10.100.0.0/16"
  vpc_id                                     = aws_vpc.main.id
  subnet_ids                                 = [aws_subnet.main["pri-1"].id, aws_subnet.main["pri-2"].id]
  create_cloudwatch_log_group                = true
  cloudwatch_log_group_class                 = "STANDARD"
  cloudwatch_log_group_retention_in_days     = 1
  cluster_enabled_log_types                  = ["audit", "api", "authenticator", "controllerManager", "scheduler"]
  # eks cluster iam role
  create_iam_role          = true
  iam_role_use_name_prefix = false
  iam_role_name            = format("%s-%s-%s-role-eks-cluster", local.corp, local.environment, local.product)
  iam_role_description     = "eks cluster iam role"
  # additional cluster security group
  create_cluster_security_group          = true
  cluster_security_group_use_name_prefix = true
  cluster_security_group_name            = format("%s-%s-%s-sg-eks-cluster", local.corp, local.environment, local.product)
  cluster_security_group_description     = "additional eks cluster security group"
  # eks node security group
  create_node_security_group                   = true
  node_security_group_use_name_prefix          = true
  node_security_group_enable_recommended_rules = false
  node_security_group_name                     = format("%s-%s-%s-sg-eks-node", local.corp, local.environment, local.product)
  node_security_group_description              = "eks node security group"

  cluster_upgrade_policy = {
    support_type = "EXTENDED"
  }
  cluster_addons = {
    coredns = {
      before_compute              = false
      addon_version               = "v1.11.4-eksbuild.2"
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "NONE"
      preserve                    = false
    }
    kube-proxy = {
      before_compute              = true
      addon_version               = "v1.32.0-eksbuild.2"
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "NONE"
      preserve                    = false
    }
    vpc-cni = {
      before_compute              = true
      addon_version               = "v1.19.2-eksbuild.1"
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "NONE"
      preserve                    = false
      service_account_role_arn    = module.controller_iam_role_with_eks_oidc.wrapper["vpc-cni"].iam_role_arn
    }
  }
  node_security_group_additional_rules = {
    # ingress
    local-vpc = { type = "ingress", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["172.27.0.0/19"], description = "from local vpc" }
    # egress
    any = { type = "egress", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], description = "to any" }
  }
  eks_managed_node_groups = {
    common-node-group = {
      # managed node group
      use_name_prefix                = true
      name                           = format("%s-%s-%s-eks-ng", local.corp, local.environment, local.product)
      min_size                       = 2
      desired_size                   = 2
      max_size                       = 2
      ami_type                       = "AL2_x86_64"
      ami_release_version            = "1.32.0-20250203"
      use_latest_ami_release_version = false
      capacity_type                  = "ON_DEMAND"
      force_update_version           = false
      instance_types                 = ["t3.xlarge"]
      labels                         = {}
      taints                         = {}
      # launch template
      create_launch_template                 = true
      use_custom_launch_template             = true
      launch_template_use_name_prefix        = true
      launch_template_name                   = format("%s-%s-%s-lt", local.corp, local.environment, local.product)
      launch_template_description            = "eks managed node group launch template"
      update_launch_template_default_version = true
      enable_monitoring                      = true
      # eks node iam role
      create_iam_role            = true
      iam_role_use_name_prefix   = false
      iam_role_attach_cni_policy = false
      iam_role_name              = format("%s-%s-%s-role-eks-node", local.corp, local.environment, local.product)
      iam_role_description       = "eks cluster node iam role"

      node_repair_config = {
        enabled = false
      }
      update_config = {
        max_unavailable = 1
      }
      metadata_options = {
        http_endpoint               = "enabled"
        http_put_response_hop_limit = 2
        http_tokens                 = "required"
      }
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            delete_on_termination = true
            encrypted             = true
            volume_size           = 20
            volume_type           = "gp3"
          }
        }
      }
      iam_role_additional_policies = {
        ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      tags                 = { Name = format("%s-%s-%s-eks-ng", local.corp, local.environment, local.product) }
      launch_template_tags = { Name = format("%s-%s-%s-lt", local.corp, local.environment, local.product) }
      iam_role_tags        = { Name = format("%s-%s-%s-role-eks-node", local.corp, local.environment, local.product) }
    }
  }

  cloudwatch_log_group_tags   = { Name = format("/aws/eks/%s-%s-%s-eks/cluster", local.corp, local.environment, local.product) }
  cluster_tags                = { Name = format("%s-%s-%s-eks", local.corp, local.environment, local.product) }
  iam_role_tags               = { Name = format("%s-%s-%s-role-eks-cluster", local.corp, local.environment, local.product) }
  cluster_security_group_tags = { Name = format("%s-%s-%s-sg-eks-cluster", local.corp, local.environment, local.product) }
  node_security_group_tags    = { Name = format("%s-%s-%s-sg-eks-node", local.corp, local.environment, local.product) }

  depends_on = [aws_route_table_association.pri-1, aws_route_table_association.pri-2]
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.33.1"

  create              = true
  create_access_entry = false
  cluster_name        = module.eks.cluster_name
  # spot instance interruption handler config
  enable_spot_termination   = true
  queue_name                = format("%s-%s-%s-sqs-karpenter", local.corp, local.environment, local.product)
  queue_managed_sse_enabled = true
  # karpenter node iam role
  create_instance_profile = false
  create_node_iam_role    = false
  node_iam_role_arn       = module.eks.eks_managed_node_groups["common-node-group"].iam_role_arn
  # karpenter pod iam role
  create_iam_role                 = true
  enable_irsa                     = true
  enable_pod_identity             = false
  enable_v1_permissions           = true
  iam_policy_name                 = format("%s-%s-%s-policy-karpenter", local.corp, local.environment, local.product)
  iam_policy_use_name_prefix      = true
  iam_policy_description          = "iam policy for karpenter irsa"
  iam_role_name                   = format("%s-%s-%s-role-karpenter", local.corp, local.environment, local.product)
  iam_role_use_name_prefix        = false
  iam_role_description            = "iam role for karpenter irsa"
  iam_role_tags                   = { Name = format("%s-%s-%s-role-karpenter", local.corp, local.environment, local.product) }
  irsa_namespace_service_accounts = ["kube-system:karpenter-sa"]
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
}

resource "helm_release" "metrics-server" {
  # target chart info
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"
  # deployment info
  name             = "metrics-server"
  create_namespace = false
  namespace        = ""
  max_history      = 2
  # install / update / rollback behavior
  atomic                = false
  dependency_update     = true
  force_update          = false
  recreate_pods         = false
  render_subchart_notes = true
  skip_crds             = false
  timeout               = 300
  # upgrade_install       = false
  wait          = true
  wait_for_jobs = true
  # chart custom values
  values = [
    templatefile(
      "${path.module}/helm/metrics-server.yaml",
      {

      }
    )
  ]
}
