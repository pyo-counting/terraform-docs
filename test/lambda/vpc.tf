locals {
  vpc_cidr = "172.28.0.0/16"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  exclude_names = ["${data.aws_region.current.name}b", "${data.aws_region.current.name}d"]
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
  enable_flow_log                   = false
  flow_log_destination_type         = "s3"
  flow_log_destination_arn          = ""
  flow_log_file_format              = "plain-text"
  flow_log_log_format               = ""
  flow_log_max_aggregation_interval = "600"
  flow_log_traffic_type             = "ALL"
  vpc_flow_log_tags                 = { Name = format("%s-%s-%s-vfl", local.corp, local.environment, local.product) }
  ### igw(internet gateway)
  create_igw = false
  ### public ngw(nat gateway)
  enable_nat_gateway                 = false
  ### vgw(virtual private gateway)
  enable_vpn_gateway = false
  # amazon_side_asn
  ### cgw(customer gateway)
  customer_gateways = {}

  ## public subnet
  public_subnets = []

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
