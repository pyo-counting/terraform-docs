locals {
  corp        = "psy"
  environment = "playground"
  product     = "test"
}

resource "aws_vpc" "main" {
  cidr_block           = "172.27.0.0/19"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "main" {
  for_each = {
    pri-1 = {
      az         = "ap-northeast-2a"
      cidr_block = "172.27.0.0/21"
    }
    pri-2 = {
      az         = "ap-northeast-2b"
      cidr_block = "172.27.8.0/21"
    }
    pub = {
      az         = "ap-northeast-2a"
      cidr_block = "172.27.16.0/21"
    }
  }

  availability_zone                           = each.value.az
  cidr_block                                  = each.value.cidr_block
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = false
  private_dns_hostname_type_on_launch         = "resource-name"
  vpc_id                                      = aws_vpc.main.id
}

resource "aws_eip" "main" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  connectivity_type = "public"
  allocation_id     = aws_eip.main.id
  subnet_id         = aws_subnet.main["pub"].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "pri-1" {
  subnet_id      = aws_subnet.main["pri-1"].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "pri-2" {
  subnet_id      = aws_subnet.main["pri-2"].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "pub" {
  subnet_id      = aws_subnet.main["pub"].id
  route_table_id = aws_route_table.public.id
}

data "aws_iam_policy_document" "vpc-cni" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
  }
}

resource "aws_iam_role" "vpc-cni" {
  name               = "psy-playground-test-role"
  assume_role_policy = data.aws_iam_policy_document.vpc-cni.json
}

resource "aws_iam_role_policy_attachment" "vpc-cni" {
  role       = aws_iam_role.vpc-cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  # eks cluster config
  create                                     = true
  create_kms_key                             = false
  cluster_encryption_config                  = {}
  enable_auto_mode_custom_tags               = false
  cluster_name                               = format("%s-%s-%s-eks-%s", local.corp, local.environment, local.product, "20250220")
  enable_cluster_creator_admin_permissions   = false
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
  iam_role_name            = format("%s-%s-%s-role-eks-cluster-%s", local.corp, local.environment, local.product, "20250220")
  iam_role_description     = "eks cluster iam role"
  # additional cluster security group
  create_cluster_security_group          = true
  cluster_security_group_use_name_prefix = true
  cluster_security_group_name            = format("%s-%s-%s-sg-eks-cluster-%s", local.corp, local.environment, local.product, "20250220")
  cluster_security_group_description     = "additional eks cluster security group"
  # eks node security group
  create_node_security_group                   = true
  node_security_group_use_name_prefix          = true
  node_security_group_enable_recommended_rules = false
  node_security_group_name                     = format("%s-%s-%s-sg-eks-node-%s", local.corp, local.environment, local.product, "20250220")
  node_security_group_description              = "eks node security group"

  cluster_upgrade_policy = {
    support_type = "EXTENDED"
  }
  access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::221082182106:role/aws-reserved/sso.amazonaws.com/ap-northeast-2/AWSReservedSSO_KURLY-ALL-Administrators_6b0f440bfaa5800d"
      type          = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
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
      service_account_role_arn    = aws_iam_role.vpc-cni.arn
    }
  }
  cluster_security_group_additional_rules = {
    # ingress
    # forti-vpn-ssl   = { type = "ingress", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["172.27.241.0/24"], description = "from forti vpn(ssl)" }
    # forti-vpn-ipsec = { type = "ingress", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["192.168.2.0/24"], description = "from forti vpn(ipsec)" }
    # argo-cd         = { type = "ingress", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["172.16.32.0/19"], description = "from argo cd(shr vpc)" }
  }
  node_security_group_additional_rules = {
    # ingress
    # forti-vpn-ssl   = { type = "ingress", from_port = 20022, to_port = 20022, protocol = "tcp", cidr_blocks = ["172.27.241.0/24"], description = "from forti vpn(ssl)" }
    # forti-vpn-ipsec = { type = "ingress", from_port = 20022, to_port = 20022, protocol = "tcp", cidr_blocks = ["192.168.2.0/24"], description = "from forti vpn(ipsec)" }
    local-vpc = { type = "ingress", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["172.27.0.0/19"], description = "from local vpc" }
    # egress
    any = { type = "egress", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], description = "to any" }
  }
  eks_managed_node_groups = {
    common-node-group = {
      # managed node group
      use_name_prefix                = true
      name                           = format("%s-%s-%s-eks-ng-%s", local.corp, local.environment, local.product, "20250220")
      min_size                       = 5
      desired_size                   = 5
      max_size                       = 5
      ami_type                       = "AL2_x86_64"
      ami_release_version            = "1.32.0-20250203"
      use_latest_ami_release_version = false
      capacity_type                  = "ON_DEMAND"
      force_update_version           = false
      instance_types                 = ["t3.xlarge"]
      labels                         = {}
      taints                         = {}
      # user data
      # launch template
      create_launch_template                 = true
      use_custom_launch_template             = true
      launch_template_use_name_prefix        = true
      launch_template_name                   = format("%s-%s-%s-lt-%s", local.corp, local.environment, local.product, "20250220")
      launch_template_description            = "eks managed node group launch template"
      update_launch_template_default_version = true
      enable_monitoring                      = true
      # eks node iam role
      create_iam_role            = true
      iam_role_use_name_prefix   = false
      iam_role_attach_cni_policy = false
      iam_role_name              = format("%s-%s-%s-role-eks-node-%s", local.corp, local.environment, local.product, "20250220")
      iam_role_description       = "eks cluster node iam role"

      node_repair_config = {
        enabled = false
      }
      update_config = {
        max_unavailable = 1
      }
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            delete_on_termination = true
            encrypted             = true
            volume_size           = 50
            volume_type           = "gp3"
          }
        }
      }
      iam_role_additional_policies = {
        ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      tags                 = { Name = format("%s-%s-%s-eks-ng-%s", local.corp, local.environment, local.product, "20250220") }
      launch_template_tags = { Name = format("%s-%s-%s-lt-%s", local.corp, local.environment, local.product, "20250220") }
      iam_role_tags        = { Name = format("%s-%s-%s-role-eks-node-%s", local.corp, local.environment, local.product, "20250220") }
    }
  }

  cloudwatch_log_group_tags   = { Name = format("/aws/eks/%s-%s-%s-eks-%s/cluster", local.corp, local.environment, local.product, "20250220") }
  cluster_tags                = { Name = format("%s-%s-%s-eks-%s", local.corp, local.environment, local.product, "20250220") }
  iam_role_tags               = { Name = format("%s-%s-%s-role-eks-cluster-%s", local.corp, local.environment, local.product, "20250220") }
  cluster_security_group_tags = { Name = format("%s-%s-%s-sg-eks-cluster-%s", local.corp, local.environment, local.product, "20250220") }
  node_security_group_tags    = { Name = format("%s-%s-%s-sg-eks-node-%s", local.corp, local.environment, local.product, "20250220") }

  depends_on = [ aws_route_table_association.pri-1, aws_route_table_association.pri-2 ]
}