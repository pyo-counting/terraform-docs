module "ec" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.4.1"

  # ec valkey replication group config
  create                                    = true
  create_replication_group                  = true
  create_primary_global_replication_group   = false
  create_secondary_global_replication_group = false
  replication_group_id                      = format("%s-%s-%s-ec-valkey", local.corp, local.environment, local.product)
  engine                                    = "valkey"
  engine_version                            = "7.2"
  node_type                                 = "cache.t4g.small"
  cluster_mode                              = "enabled"
  cluster_mode_enabled                      = true
  num_node_groups                           = 1 # valid when cluster mode enabled
  replicas_per_node_group                   = 0 # valid when cluster mode enabled(min 2, when automatic_failover_enabled or multi_az_enabled is true)
  # num_cache_clusters                        = 2 # valid when cluster mode disabled
  automatic_failover_enabled = false # muste be true when cluster mode enabled or multi az enabled
  multi_az_enabled           = false
  # preferred_cache_cluster_azs = ["${local.region}a", "${local.region}c"] # valid when cluster mode disabled
  data_tiering_enabled = false
  user_group_ids       = []
  description          = "ec valkey replication group"
  tags                 = { Name = format("%s-%s-%s-ec-valkey", local.corp, local.environment, local.product) }
  log_delivery_configuration = {
    defaults = {
      create_cloudwatch_log_group = true
      destination_type            = "cloudwatch-logs"
      log_format                  = "json"
      log_type                    = "slow-log"
    }
  }
  # security group
  create_security_group          = true
  security_group_use_name_prefix = true
  vpc_id                         = aws_vpc.main.id
  security_group_name            = format("%s-%s-%s-sg-ec-valkey", local.corp, local.environment, local.product)
  security_group_rules = {
    # ingress
    local_vpc = { type = "ingress", from_port = 6379, to_port = 6379, ip_protocol = "tcp", cidr_ipv4 = "172.28.0.0/19", description = "from local vpc" }
  }
  security_group_description = "ec valkey replication group secrurity group"
  security_group_tags        = { Name = format("%s-%s-%s-sg-ec-valkey", local.corp, local.environment, local.product) }
  # network config
  create_subnet_group      = true
  subnet_ids               = [aws_subnet.main["pri_1"].id, aws_subnet.main["pri_2"].id]
  subnet_group_name        = format("%s-%s-%s-sbng-ec-valkey", local.corp, local.environment, local.product)
  ip_discovery             = "ipv4"
  network_type             = "ipv4"
  port                     = "6379"
  subnet_group_description = "ec valkey replicateion group subnet group"
  # parameter group
  create_parameter_group      = true
  parameter_group_family      = "valkey7"
  parameter_group_name        = format("%s-%s-%s-pargp-ec-valkey7", local.corp, local.environment, local.product)
  parameters                  = [{ name = "cluster-enabled", value = "yes" }]
  parameter_group_description = "ec valkey replicateion group parameter group(valkey7)"
  # encryption config
  at_rest_encryption_enabled = true
  kms_key_arn                = ""
  transit_encryption_enabled = false
  # snapshot config
  snapshot_retention_limit  = 1
  snapshot_window           = "17:00-18:00" # (KST) 06:00 - 07:00
  final_snapshot_identifier = ""
  # update policy
  apply_immediately          = true
  auto_minor_version_upgrade = false
  maintenance_window         = "sat:19:00-sat:21:00" # (KST) sun:04:00 - sun:06:00
}