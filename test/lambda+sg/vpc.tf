locals {
  vpc_cidr = "172.28.0.0/16"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  exclude_names = ["${data.aws_region.current.name}b", "${data.aws_region.current.name}d"]
}

data "aws_prefix_list" "s3" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${data.aws_region.current.name}.s3"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  ## vpc
  create_vpc                           = true
  name                                 = format("%s-%s-%s-vpc", local.corp, local.environment, local.product)
  azs                                  = data.aws_availability_zones.available.names
  cidr                                 = local.vpc_cidr
  secondary_cidr_blocks                = []
  use_ipam_pool                        = false
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_ipv6                          = false
  enable_network_address_usage_metrics = false
  vpc_tags                             = { Name = format("%s-%s-%s-vpc", local.corp, local.environment, local.product) }
  ### dhcp
  enable_dhcp_options = false
  ### vpc flow log(s3)
  enable_flow_log = false
  ### igw(internet gateway)
  create_igw = true
  ### public ngw(nat gateway)
  enable_nat_gateway                 = true
  reuse_nat_ips                      = false
  one_nat_gateway_per_az             = true
  single_nat_gateway                 = false
  nat_gateway_destination_cidr_block = "0.0.0.0/0"
  nat_gateway_tags                   = { Name = format("%s-%s-%s-ngw-%s", local.corp, local.environment, local.product, "pub") }
  nat_eip_tags                       = { Name = format("%s-%s-%s-eip", local.corp, local.environment, local.product) }
  ### vgw(virtual private gateway)
  enable_vpn_gateway = false
  # amazon_side_asn
  ### cgw(customer gateway)
  customer_gateways = {}

  ## public subnet
  public_subnets = [
    cidrsubnet(local.vpc_cidr, 8, 0),
    cidrsubnet(local.vpc_cidr, 8, 1)
  ]
  public_subnet_names = [
    format("%s-%s-%s-sbn-%s", local.corp, local.environment, local.product, "pub-a"),
    format("%s-%s-%s-sbn-%s", local.corp, local.environment, local.product, "pub-c")
  ]
  public_subnet_enable_dns64                                   = false
  public_subnet_assign_ipv6_address_on_creation                = false
  public_subnet_enable_resource_name_dns_a_record_on_launch    = false
  public_subnet_enable_resource_name_dns_aaaa_record_on_launch = false
  public_subnet_private_dns_hostname_type_on_launch            = "ip-name"
  map_public_ip_on_launch                                      = false
  public_subnet_tags                                           = {}
  public_subnet_tags_per_az                                    = {}
  ### public subnet route table
  create_multiple_public_route_tables = false
  public_route_table_tags             = { Name = format("%s-%s-%s-rt-%s", local.corp, local.environment, local.product, "pub") }
  ### public subnet acl
  public_dedicated_network_acl = false
  # public_inbound_acl_rules
  # public_outbound_acl_rules
  # public_acl_tags

  ## private db subnet
  database_subnets = []

  ## private subnet
  private_subnets = [
    cidrsubnet(local.vpc_cidr, 8, 4),
    cidrsubnet(local.vpc_cidr, 8, 5)
  ]
  private_subnet_names = [
    format("%s-%s-%s-sbn-%s", local.corp, local.environment, local.product, "pri-a"),
    format("%s-%s-%s-sbn-%s", local.corp, local.environment, local.product, "pri-c"),
  ]
  private_subnet_enable_dns64                                   = false
  private_subnet_assign_ipv6_address_on_creation                = false
  private_subnet_enable_resource_name_dns_a_record_on_launch    = false
  private_subnet_enable_resource_name_dns_aaaa_record_on_launch = false
  private_subnet_private_dns_hostname_type_on_launch            = "ip-name"
  private_subnet_tags                                           = {}
  private_subnet_tags_per_az                                    = {}
  ### private route table
  create_private_nat_gateway_route = true
  private_route_table_tags         = { Name = format("%s-%s-%s-rt-%s", local.corp, local.environment, local.product, "pri") }
  ### private subnet acl
  private_dedicated_network_acl = false
  # private_inbound_acl_rules
  # private_outbound_acl_rules
  # private_acl_tags

  ## private ec subnet
  elasticache_subnets = []

  ## private private redshift subnet
  redshift_subnets = []

  ## intra subnet
  intra_subnets = []

  ## outpost subnet
  outpost_subnets = []

  ## default vpc
  manage_default_vpc            = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  tags = {}
}

module "sg_lambda" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  ## general
  create                 = true
  create_sg              = true
  use_name_prefix        = true
  name                   = format("%s-%s-%s-sg-%s", local.corp, local.environment, local.product, "lambda")
  description            = "sg for lambda"
  vpc_id                 = module.vpc.vpc_id
  revoke_rules_on_delete = false
  security_group_id      = null

  ## egress rule
  # egress_cidr_blocks      = []
  # egress_prefix_list_ids  = []
  # egress_with_cidr_blocks = []
  egress_with_prefix_list_ids = [
    {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      prefix_list_ids = data.aws_prefix_list.s3.id
      description     = "Allow Lambda to S3 via HTTPS"
    }
  ]
  # egress_with_self                     = []
  # egress_with_source_security_group_id = []

  ## ingress rule
  # ingress_cidr_blocks                   = []
  # ingress_prefix_list_ids               = []
  # ingress_with_cidr_blocks              = []
  # ingress_with_prefix_list_ids          = []
  # ingress_with_self                     = []
  # ingress_with_source_security_group_id = []

  # create_timeout = ""
  # delete_timeout = ""
  tags = { Name = format("%s-%s-%s-sg-%s", local.corp, local.environment, local.product, "lambda") }
}
