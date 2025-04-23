module "sqs" {
  source  = "terraform-aws-modules/sqs/aws//wrappers"
  version = "4.3.1"

  defaults = {
    create = true
  }
  items = {
    test = {
      # sqs/dlq common config
      use_name_prefix = false
      # sqs
      name = format("%s-%s-%s-sqs", local.corp, local.environment, local.product)
      # sqs policy
      create_queue_policy     = false
      queue_policy_statements = {}
      # sqs redrive policy
      redrive_allow_policy = {}
      redrive_policy = {
        maxReceiveCount = 5
      }
      # sqs config
      delay_seconds              = 0
      message_retention_seconds  = 345600 # 4d
      visibility_timeout_seconds = 370    # 6m10s
      receive_wait_time_seconds  = 20
      sqs_managed_sse_enabled    = true
      # max_message_size
      # kms_data_key_reuse_period_seconds
      # kms_master_key_id
      tags = { name = format("%s-%s-%s-sqs", local.corp, local.environment, local.product) }
      # dlq
      create_dlq = true
      dlq_name   = format("%s-%s-%s-dlq", local.corp, local.environment, local.product)
      # dlq policy
      create_dlq_queue_policy     = false
      dlq_queue_policy_statements = {}
      # dlq redrive policy
      create_dlq_redrive_allow_policy = true
      dlq_redrive_allow_policy        = {}
      # dlq config
      dlq_delay_seconds             = 0
      dlq_message_retention_seconds = 1209600 # 14d
      # dlq_visibility_timeout_seconds
      # dlq_receive_wait_time_seconds
      dlq_sqs_managed_sse_enabled = true
      # dlq_kms_data_key_reuse_period_seconds
      # dlq_kms_master_key_id
      dlq_tags = { name = format("%s-%s-%s-dlq", local.corp, local.environment, local.product) }
    }
  }
}