data "aws_region" "current" {}

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
  subnet_ids                                 = [aws_subnet.main["pri_1"].id, aws_subnet.main["pri_2"].id]
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
  access_entries = {
    # data plane
    node_ec2 = {
      principal_arn = module.iam_role.wrapper["eks_node_ec2"].iam_role_arn
      type          = "EC2_LINUX"
    }
  }
  cluster_addons = {
    coredns = {
      before_compute              = false
      addon_version               = "v1.11.4-eksbuild.2"
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "PRESERVE"
      preserve                    = false
      configuration_values        = jsonencode(yamldecode(file("${path.module}/config/eks/coredns/v1.11.4-eksbuild.2/aws-addon/values.yaml")))
    }
    kube-proxy = {
      before_compute              = true
      addon_version               = "v1.32.0-eksbuild.2"
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "PRESERVE"
      preserve                    = false
      # configuration_values        = jsonencode(yamldecode(file("${path.module}/config/eks/kube-proxy/v1.32.0-eksbuild.2/aws-addon/values.yaml")))
    }
    vpc-cni = {
      before_compute              = true
      addon_version               = "v1.19.2-eksbuild.1"
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "PRESERVE"
      preserve                    = false
      service_account_role_arn    = module.iam_role_with_eks_oidc_system.wrapper["vpc_cni"].iam_role_arn
      # configuration_values        = jsonencode(yamldecode(file("${path.module}/config/eks/vpc-cni/v1.19.2-eksbuild.1/aws-addon/values.yaml")))
    }
  }
  cluster_security_group_additional_rules = {}
  node_security_group_additional_rules = {
    # ingress
    local_vpc = { type = "ingress", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["172.27.0.0/19"], description = "from local vpc" }
    # egress
    any = { type = "egress", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], description = "to any" }
  }
  eks_managed_node_groups = {
    system = {
      # managed node group
      use_name_prefix                = true
      name                           = format("%s-%s-%s-eks-ng-%s", local.corp, local.environment, local.product, "system")
      min_size                       = 2
      desired_size                   = 2
      max_size                       = 4
      ami_type                       = "AL2_x86_64"
      ami_release_version            = "1.32.0-20250203"
      use_latest_ami_release_version = false
      capacity_type                  = "ON_DEMAND"
      force_update_version           = false
      instance_types                 = ["t3.large"]
      labels                         = {}
      taints = {
        managed_by = {
          key    = "node.pyo-counting.io/managed-by"
          value  = "mng"
          effect = "NO_EXECUTE"
        }
        capacity_type = {
          key    = "node.pyo-counting.io/capacity-type"
          value  = "on-demand"
          effect = "NO_EXECUTE"
        }
      }
      # user data
      pre_bootstrap_user_data = file("${path.module}/config/ec2/al2-1.32.0-20250203-userdata.sh")
      # launch template
      create_launch_template                 = true
      use_custom_launch_template             = true
      launch_template_use_name_prefix        = true
      launch_template_name                   = format("%s-%s-%s-lt-%s", local.corp, local.environment, local.product, "system")
      launch_template_description            = "eks system managed node group launch template"
      update_launch_template_default_version = true
      enable_monitoring                      = true
      # eks node iam role
      create_iam_role = false
      iam_role_arn    = module.iam_role.wrapper["eks_node_ec2"].iam_role_arn

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
      tags                 = { Name = format("%s-%s-%s-eks-ng-%s", local.corp, local.environment, local.product, "system") }
      launch_template_tags = { Name = format("%s-%s-%s-lt-%s", local.corp, local.environment, local.product, "system") }
    }
  }

  cloudwatch_log_group_tags   = { Name = format("/aws/eks/%s-%s-%s-eks/cluster", local.corp, local.environment, local.product) }
  cluster_tags                = { Name = format("%s-%s-%s-eks", local.corp, local.environment, local.product) }
  iam_role_tags               = { Name = format("%s-%s-%s-role-eks-cluster", local.corp, local.environment, local.product) }
  cluster_security_group_tags = { Name = format("%s-%s-%s-sg-eks-cluster", local.corp, local.environment, local.product) }
  node_security_group_tags    = { Name = format("%s-%s-%s-sg-eks-node", local.corp, local.environment, local.product) }

  depends_on = [
    aws_route_table_association.pri_1,
    aws_route_table_association.pri_2,
    aws_route_table_association.pub
  ]
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
  # node iam role
  create_node_iam_role    = false
  create_instance_profile = false
  node_iam_role_arn       = module.iam_role.wrapper["eks_node_ec2"].iam_role_arn
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

resource "helm_release" "karpenter_crd" {
  # chart info
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter-crd"
  version    = "1.3.2"
  # deployment info
  name             = "karpenter-crd"
  create_namespace = false
  namespace        = "kube-system"
  max_history      = 2
  # install / update / rollback behavior
  atomic                = false
  cleanup_on_fail       = false
  dependency_update     = true
  force_update          = false
  recreate_pods         = false
  replace               = false
  render_subchart_notes = true
  reset_values          = false
  reuse_values          = false
  skip_crds             = false
  timeout               = 300 # 5m
  upgrade_install       = false
  wait                  = true
  wait_for_jobs         = true
  # chart custom values
  values = []

  depends_on = [module.eks]
}

resource "helm_release" "karpenter" {
  # chart info
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.3.2"
  # deployment info
  name             = "karpenter"
  create_namespace = false
  namespace        = "kube-system"
  max_history      = 2
  # install / update / rollback behavior
  atomic                = false
  cleanup_on_fail       = false
  dependency_update     = true
  force_update          = false
  recreate_pods         = false
  replace               = false
  render_subchart_notes = true
  reset_values          = false
  reuse_values          = false
  skip_crds             = true
  timeout               = 300 # 5m
  upgrade_install       = false
  wait                  = true
  wait_for_jobs         = true
  # chart custom values
  values = [templatefile("${path.module}/config/eks/karpenter/1.3.2/helm/values.yaml.tftpl",
    {
      environment      = local.environment
      cluster          = module.eks.cluster_name
      cluster_endpoint = module.eks.cluster_endpoint
      sqs              = module.karpenter.queue_name
      iam_irsa_arn     = module.karpenter.iam_role_arn
      service_account  = "karpenter-sa"
    }
  )]

  depends_on = [
    module.eks,
    module.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_ec2nc_default" {
  server_side_apply = true
  wait              = true
  yaml_body = templatefile("${path.module}/config/eks/karpenter/1.3.2/manifest/ec2nc-default.yaml.tftpl",
    {
      subnet_ids           = [aws_subnet.main["pri_1"].id, aws_subnet.main["pri_2"].id]
      security_group_id    = module.eks.node_security_group_id
      iam_instance_profile = module.iam_role.wrapper["eks_node_ec2"].iam_instance_profile_name
      ami_alias            = "al2@v20250203"
      # metadata_options
      http_endpoint               = "enabled"
      http_put_response_hop_limit = 2
      http_tokens                 = "required"
      # block_device_mappings
      device_name           = "/dev/xvda"
      delete_on_termination = true
      encrypted             = true
      volume_size           = "20Gi"
      volume_type           = "gp3"
      user_data             = indent(4, file("${path.module}/config/ec2/al2-1.32.0-20250203-userdata.sh"))
      detailed_monitoring   = true
    }
  )

  depends_on = [
    helm_release.karpenter_crd,
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_nop" {
  for_each = fileset("${path.module}/config/eks/karpenter/1.3.2/manifest", "nop-*.yaml")

  server_side_apply = true
  wait              = true
  yaml_body         = file("${path.module}/config/eks/karpenter/1.3.2/manifest/${each.key}")

  depends_on = [kubectl_manifest.karpenter_ec2nc_default]
}

resource "helm_release" "aws_efs_csi_driver" {
  # chart info
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  version    = "3.1.7"
  # deployment info
  name             = "aws-efs-csi-driver"
  create_namespace = false
  namespace        = "kube-system"
  max_history      = 2
  # install / update / rollback behavior
  atomic                = false
  cleanup_on_fail       = false
  dependency_update     = true
  force_update          = false
  recreate_pods         = false
  replace               = false
  render_subchart_notes = true
  reset_values          = false
  reuse_values          = false
  skip_crds             = true
  timeout               = 300 # 5m
  upgrade_install       = false
  wait                  = true
  wait_for_jobs         = true
  # chart custom values
  values = [templatefile("${path.module}/config/eks/aws-efs-csi-driver/3.1.7/helm/values.yaml.tftpl",
    {
      #  controller pod
      controller_iam_irsa_arn    = module.iam_role_with_eks_oidc_system.wrapper["aws_efs_csi"].iam_role_arn
      controller_service_account = "efs-csi-controller-sa"
      # node pod
      node_iam_irsa_arn    = module.iam_role_with_eks_oidc_system.wrapper["aws_efs_csi"].iam_role_arn
      node_service_account = "efs-csi-node-sa"
    }
  )]

  depends_on = [module.eks]
}

resource "helm_release" "metrics_server" {
  # chart info
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"
  # deployment info
  name             = "metrics-server"
  create_namespace = false
  namespace        = "kube-system"
  max_history      = 2
  # install / update / rollback behavior
  atomic                = false
  cleanup_on_fail       = false
  dependency_update     = true
  force_update          = false
  recreate_pods         = false
  replace               = false
  render_subchart_notes = true
  reset_values          = false
  reuse_values          = false
  skip_crds             = true
  timeout               = 300 # 5m
  upgrade_install       = false
  wait                  = true
  wait_for_jobs         = true
  # chart custom values
  values = [file("${path.module}/config/eks/metrics-server/0.7.2/helm/values.yaml")]

  depends_on = [module.eks]
}

resource "helm_release" "secrets_store_csi_driver" {
  # chart info
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.8"
  # deployment info
  name             = "secrets-store-csi-driver"
  create_namespace = false
  namespace        = "kube-system"
  max_history      = 2
  # install / update / rollback behavior
  atomic                = false
  cleanup_on_fail       = false
  dependency_update     = true
  force_update          = false
  recreate_pods         = false
  replace               = false
  render_subchart_notes = true
  reset_values          = false
  reuse_values          = false
  skip_crds             = false
  timeout               = 300 # 5m
  upgrade_install       = false
  wait                  = true
  wait_for_jobs         = true
  # chart custom values
  values = [file("${path.module}/config/eks/secrets-store-csi-driver/1.4.8/helm/values.yaml")]

  depends_on = [module.eks]
}

resource "helm_release" "secrets_store_csi_driver_provider_aws" {
  # chart info
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = "0.3.10"
  # deployment info
  name             = "secrets-store-csi-driver-provider-aws"
  create_namespace = false
  namespace        = "kube-system"
  max_history      = 2
  # install / update / rollback behavior
  atomic                = false
  cleanup_on_fail       = false
  dependency_update     = true
  force_update          = false
  recreate_pods         = false
  replace               = false
  render_subchart_notes = true
  reset_values          = false
  reuse_values          = false
  skip_crds             = false
  timeout               = 300 # 5m
  upgrade_install       = false
  wait                  = true
  wait_for_jobs         = true
  # chart custom values
  values = [file("${path.module}/config/eks/secrets-store-csi-driver-provider-aws/0.3.10/helm/values.yaml")]

  depends_on = [helm_release.secrets_store_csi_driver]
}

resource "helm_release" "aws_load_balancer_controller" {
  # chart info
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.2"
  # deployment info
  name             = "aws-load-balancer-controller"
  create_namespace = false
  namespace        = "kube-system"
  max_history      = 2
  # install / update / rollback behavior
  atomic                = false
  cleanup_on_fail       = false
  dependency_update     = true
  force_update          = false
  recreate_pods         = false
  replace               = false
  render_subchart_notes = true
  reset_values          = false
  reuse_values          = false
  skip_crds             = false
  timeout               = 300 # 5m
  upgrade_install       = false
  wait                  = true
  wait_for_jobs         = true
  # chart custom values
  values = [templatefile("${path.module}/config/eks/aws-load-balancer-controller/1.7.2/helm/values.yaml.tftpl",
    {
      cluster         = module.eks.cluster_name
      service_account = "aws-load-balancer-controller-sa"
      iam_irsa_arn    = module.iam_role_with_eks_oidc_system.wrapper["aws_load_balancer"].iam_role_arn
    }
  )]

  depends_on = [module.eks]
}

resource "kubectl_manifest" "alloy_ns" {
  server_side_apply = true
  wait              = true
  yaml_body         = file("${path.module}/config/eks/alloy/1.0.3/manifest/ns.yaml")

  depends_on = [module.eks]
}

resource "helm_release" "alloy" {
  # chart info
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.0.3"
  # deployment info
  name             = "alloy"
  create_namespace = false
  namespace        = "alloy-ns"
  max_history      = 2
  # install / update / rollback behavior
  atomic                = false
  cleanup_on_fail       = false
  dependency_update     = true
  force_update          = false
  recreate_pods         = false
  replace               = false
  render_subchart_notes = true
  reset_values          = false
  reuse_values          = false
  skip_crds             = false
  timeout               = 300 # 5m
  upgrade_install       = false
  wait                  = true
  wait_for_jobs         = true
  # chart custom values
  values = [templatefile("${path.module}/config/eks/alloy/1.0.3/helm/values.yaml.tftpl", {
    environment = local.environment,
    alloy_config = indent(6, templatefile("${path.module}/config/eks/alloy/1.0.3/helm/config.alloy", {
      aws_account    = "test"
      aws_account_id = "test"
      cluster        = module.eks.cluster_name
      loki_host      = "loki.pyo-counting.services"
    }))
  })]

  depends_on = [kubectl_manifest.alloy_ns]
}
