data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/example-go/bootstrap"
  output_path = "lambda.zip"
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.2"

  ## general
  create                 = true
  create_function        = true
  lambda_at_edge         = false
  skip_destroy           = false
  publish                = true
  function_name          = format("%s-%s-%s-lambda", local.corp, local.environment, local.product)
  description            = "lambda"
  architectures          = ["arm64"]
  ephemeral_storage_size = 512 # 512GB
  memory_size            = 256 # 256MB
  timeout                = 10  # 10s
  # provisioned_concurrent_executions = null
  # reserved_concurrent_executions    = null
  ## efs
  # file_system_arn              = ""
  # file_system_local_mount_path = ""
  ## package
  package_type = "Zip"
  ### zip
  handler                 = "bootstrap"
  runtime                 = "provided.al2023"
  local_existing_package  = data.archive_file.lambda_zip.output_path
  ignore_source_code_hash = false
  # snap_start              = null
  ### image
  # image_uri = ""
  # image_config_command           = []
  # image_config_entry_point       = []
  # image_config_working_directory = ""
  ## vpc
  ipv6_allowed_for_dual_stack        = false
  vpc_subnet_ids                     = module.vpc.private_subnets
  vpc_security_group_ids             = [module.sg_lambda.security_group_id]
  replace_security_groups_on_destroy = false
  # replacement_security_group_ids     = []
  ## env
  # kms_key_arn = ""
  environment_variables = {
    RECEIPT_BUCKET = module.s3_bucket.s3_bucket_id
  }
  ## trace
  # tracing_mode = ""
  ## log
  use_existing_cloudwatch_log_group = false
  # logging_log_group               = ""
  cloudwatch_logs_skip_destroy      = false
  logging_application_log_level     = "INFO"
  logging_system_log_level          = "INFO"
  logging_log_format                = "Text"
  cloudwatch_logs_log_group_class   = "STANDARD"
  cloudwatch_logs_retention_in_days = 7 # 7d
  # lambda_at_edge_logs_all_regions = null
  # cloudwatch_logs_kms_key_id        = ""
  cloudwatch_logs_tags = { Name = format("/aws/lambda/%s", "lambda") }
  ## tags
  include_default_tag = true
  function_tags       = { Name = format("%s-%s-%s-lambda", local.corp, local.environment, local.product) }
  ## trigger invocation
  create_current_version_allowed_triggers   = true
  create_unqualified_alias_allowed_triggers = true
  event_source_mapping                      = {}
  ## async invocation
  create_async_event_config = false
  # create_current_version_async_event_config   = true
  # create_unqualified_alias_async_event_config = true
  # dead_letter_target_arn                      = ""
  # destination_on_failure                      = ""
  # destination_on_success                      = ""
  # maximum_event_age_in_seconds                = null
  # maximum_retry_attempts                      = null
  ## url
  create_lambda_function_url = false
  # create_unqualified_alias_lambda_function_url = true
  # authorization_type                           = "NONE"
  # invoke_mode                                  = ""
  # cors                                         = {}
  ## resource-based policy
  allowed_triggers = {
    cloudwatch_log_subscription_filter = {
      service = "logs"
    }
  }
  ## role
  create_role      = true
  role_name        = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "lambda")
  role_description = "iam role for lambda"
  # role_path                          = ""
  # lambda_role                        = ""
  # role_permissions_boundary          = ""
  # role_maximum_session_duration      = null
  role_force_detach_policies         = true
  policy_name                        = format("%s-%s-%s-policy-%s", local.corp, local.environment, local.product, "lambda")
  attach_async_event_policy          = false
  attach_cloudwatch_logs_policy      = true
  attach_create_log_group_permission = true
  attach_dead_letter_policy          = false
  attach_network_policy              = true
  attach_tracing_policy              = false
  attach_policy                      = false
  policy                             = ""
  attach_policies                    = false
  policies                           = []
  attach_policy_json                 = false
  policy_json                        = ""
  attach_policy_jsons                = false
  policy_jsons                       = []
  attach_policy_statements           = true
  policy_statements = {
    s3 = {
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${module.s3_bucket.s3_bucket_arn}/*"]
    }
  }
  # trusted_entities                   = []
  # policy_path                        = ""
  # assume_role_policy_statements      = {}
  role_tags = { Name = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "lambda") }
  ## layer
  create_layer = false
  ## code signing
  code_signing_config_arn = ""
  ## package
  create_package = false
  ## docker
  build_in_docker = false
  ## sam
  create_sam_metadata = false

  # timeouts = {}
  tags = {}
}

# module "lambda_lambdapromtail" {
#   source  = "terraform-aws-modules/lambda/aws"
#   version = "7.20.2"
#   providers = {
#     aws = aws.log
#   }

#   ## general
#   create                 = true
#   create_function        = true
#   lambda_at_edge         = false
#   skip_destroy           = false
#   publish                = true
#   function_name          = format("%s-%s-%s-lambda-%s", local.corp, local.environment, local.product, "lambdapromtail")
#   description            = "lambdapromtail"
#   architectures          = ["arm64"]
#   ephemeral_storage_size = 512  # 512MB
#   memory_size            = 1024 # 1GB
#   timeout                = 60   # 60s
#   # provisioned_concurrent_executions = null
#   # reserved_concurrent_executions    = null
#   # timeouts                          = {}
#   ## efs
#   # file_system_arn              = ""
#   # file_system_local_mount_path = ""
#   ## package
#   package_type = "Image"
#   ### zip
#   # handler                 = ""
#   # runtime                 = ""
#   # snap_start              = null
#   # ignore_source_code_hash = null
#   # local_existing_package  = ""
#   ### image
#   image_uri = "${data.terraform_remote_state.shr.outputs.ecr_wrapper["lambda_promtail"].repository_url}:main-ad279e5-arm64"
#   # image_config_command           = []
#   # image_config_entry_point       = []
#   # image_config_working_directory = ""
#   ## vpc
#   ipv6_allowed_for_dual_stack        = false
#   vpc_subnet_ids                     = [module.vpc.sbn_map["svr-a"].id, module.vpc.sbn_map["svr-c"].id]
#   vpc_security_group_ids             = [module.scg.scg_map["lambdapromtail"].id]
#   replace_security_groups_on_destroy = false
#   # replacement_security_group_ids     = []
#   ## env
#   # kms_key_arn = ""
#   environment_variables = {
#     WRITE_ADDRESS            = "https://promtail.pyo-counting.services/loki/api/v1/push"
#     KEEP_STREAM              = "true"
#     BATCH_SIZE               = "65536" # 64KB
#     EXTRA_LABELS             = "aws_account,logarchive,aws_account_id,073877294291"
#     OMIT_EXTRA_LABELS_PREFIX = "true"
#     TENANT_ID                = "pyo-counting"
#     SKIP_TLS_VERIFY          = "false"
#     PRINT_LOG_LINE           = "false"
#   }
#   ## trace
#   # tracing_mode = ""
#   ## log
#   use_existing_cloudwatch_log_group = false
#   # logging_log_group               = ""
#   cloudwatch_logs_skip_destroy      = false
#   logging_application_log_level     = "INFO"
#   logging_system_log_level          = "INFO"
#   logging_log_format                = "Text"
#   cloudwatch_logs_log_group_class   = "STANDARD"
#   cloudwatch_logs_retention_in_days = 7 # 7d
#   # lambda_at_edge_logs_all_regions = null
#   # cloudwatch_logs_kms_key_id        = ""
#   cloudwatch_logs_tags = { Name = format("/aws/lambda/%s", "lambdapromtail") }
#   ## tags
#   include_default_tag = true
#   function_tags       = { Name = format("%s-%s-%s-lambda-%s", local.corp, local.environment, local.product, "lambdapromtail") }
#   ## trigger invocation
#   create_current_version_allowed_triggers   = true
#   create_unqualified_alias_allowed_triggers = true
#   event_source_mapping = {
#     sqs = {
#       event_source_arn                   = module.sqs_lambdapromtail.queue_arn
#       batch_size                         = 2
#       maximum_batching_window_in_seconds = 5
#       function_response_types            = ["ReportBatchItemFailures"]
#       scaling_config = {
#         maximum_concurrency = 50
#       }
#     }
#   }
#   ## async invocation
#   create_async_event_config = false
#   # create_current_version_async_event_config   = true
#   # create_unqualified_alias_async_event_config = true
#   # dead_letter_target_arn                      = ""
#   # destination_on_failure                      = ""
#   # destination_on_success                      = ""
#   # maximum_event_age_in_seconds                = null
#   # maximum_retry_attempts                      = null
#   ## url
#   create_lambda_function_url = false
#   # create_unqualified_alias_lambda_function_url = true
#   # authorization_type                           = "NONE"
#   # invoke_mode                                  = ""
#   # cors                                         = {}
#   ## resource-based policy
#   allowed_triggers = {
#     cloudwatch_log_subscription_filter = {
#       service = "logs"
#     }
#   }
#   ## role
#   create_role      = true
#   role_name        = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "lambdapromtail")
#   role_description = "iam role for lambdapromtail"
#   # role_path                          = ""
#   # lambda_role                        = ""
#   # role_permissions_boundary          = ""
#   # role_maximum_session_duration      = null
#   role_force_detach_policies         = true
#   policy_name                        = format("%s-%s-%s-policy-%s", local.corp, local.environment, local.product, "lambdapromtail")
#   attach_async_event_policy          = false
#   attach_cloudwatch_logs_policy      = true
#   attach_create_log_group_permission = true
#   attach_dead_letter_policy          = false
#   attach_network_policy              = true
#   attach_tracing_policy              = false
#   attach_policy                      = true
#   policy                             = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
#   attach_policies                    = false
#   policies                           = []
#   attach_policy_json                 = false
#   policy_json                        = ""
#   attach_policy_jsons                = false
#   policy_jsons                       = []
#   attach_policy_statements           = true
#   policy_statements = {
#     s3 = {
#       effect    = "Allow"
#       actions   = ["s3:GetObject"]
#       resources = ["${module.s3_bucket_lambdapromtail.s3_bucket_arn}/*"]
#     }
#   }
#   # trusted_entities                   = []
#   # policy_path                        = ""
#   # assume_role_policy_statements      = {}
#   role_tags = { Name = format("%s-%s-%s-role-%s", local.corp, local.environment, local.product, "lambdapromtail") }
#   ## layer
#   create_layer = false
#   ## code signing
#   code_signing_config_arn = ""
#   ## package
#   create_package = false
#   ## docker
#   build_in_docker = false
#   ## sam
#   create_sam_metadata = false

#   tags = {}
# }
