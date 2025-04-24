module "sm" {
  source  = "terraform-aws-modules/secrets-manager/aws//wrappers"
  version = "1.3.1"

  defaults = {
    create                  = true
    recovery_window_in_days = 7

    ## policy
    block_public_policy = true
    create_policy       = false
    # override_policy_documents = []
    # policy_statements = {}
    # source_policy_documents = []

    ## version
    ignore_secret_changes  = true
    create_random_password = true # initial random secret
    random_password_length = 32
    # secret_binary = null
    # secret_string = null
    # version_stages = {}

    ## rotation
    enable_rotation = false
    # rotation_lambda_arn = ""
    # rotation_rules = {}

    ## encryption
    # kms_key_id = null

    ## replication
    force_overwrite_replica_secret = false
    # replica = {}
  }
  items = {
    test1 = {
      name        = format("%s-%s-%s-sm", local.corp, local.environment, "test1")
      description = "secret manager for test1 domain"
      tags        = { Name = format("%s-%s-%s-sm", local.corp, local.environment, "test1") }
    }
    test2 = {
      name        = format("%s-%s-%s-sm", local.corp, local.environment, "test2")
      description = "secret manager for test2 domain"
      tags        = { Name = format("%s-%s-%s-sm", local.corp, local.environment, "test2") }
    }
  }
}