module "s3_bucket_source" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.2"

  bucket        = format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "source")
  create_bucket = true
  force_destroy = false
  # bucket policy
  attach_policy                  = true
  attach_elb_log_delivery_policy = false
  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = [
          "arn:aws:s3:::${format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "source")}/*",
          "arn:aws:s3:::${format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "source")}"
        ]
      }
    ]
  })
  # public access policy
  attach_public_policy    = true
  block_public_policy     = true
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  # bucket config
  intelligent_tiering = {}
  lifecycle_rule = [
    {
      id      = "periodic-expiration"
      enabled = true
      expiration = {
        days = 365 # 1y
      }
      noncurrent_version_expiration = {
        noncurrent_days = 1 # 1d
      }
    }
  ]
  logging              = {}
  metric_configuration = []
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true

      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning = { enabled = true }
  replication_configuration = {
    role = module.iam_role_s3_replication.iam_role_arn
    rules = [
      {
        id                        = "waf-acl-logs"
        status                    = true
        priority                  = 1
        delete_marker_replication = false
        filter = {
          prefix = "AWSLogs/"
        }
        source_selection_criteria = {
          replica_modifications = {
            status = "Disabled"
          }
        }
        destination = {
          bucket = module.s3_bucket_destination.s3_bucket_arn
          metrics = {
            status  = "Enabled"
            minutes = 15
          }
          replication_time = {
            status  = "Enabled"
            minutes = 15
          }
        }
      }
    ]
  }
  tags = { Name = format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "source") }
}

module "s3_bucket_destination" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.2"

  bucket        = format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "destination")
  create_bucket = true
  force_destroy = false
  # bucket policy
  attach_policy                  = true
  attach_elb_log_delivery_policy = false
  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = [
          "arn:aws:s3:::${format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "destination")}/*",
          "arn:aws:s3:::${format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "destination")}"
        ]
      }
    ]
  })
  # public access policy
  attach_public_policy    = true
  block_public_policy     = true
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  # bucket config
  intelligent_tiering = {}
  lifecycle_rule = [
    {
      id      = "periodic-expiration"
      enabled = true
      expiration = {
        days = 7 # 1w
      }
      noncurrent_version_expiration = {
        noncurrent_days = 1 # 1d
      }
    }
  ]
  logging              = {}
  metric_configuration = []
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true

      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning                = { enabled = true }
  replication_configuration = {}
  tags                      = { Name = format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "destination") }
}

module "s3_bucket_notification_destination" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "4.7.0"

  bucket            = module.s3_bucket_destination.s3_bucket_id
  create            = true
  create_sqs_policy = true
  sqs_notifications = {
    test = {
      queue_arn     = module.sqs_test.queue_arn_static
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = "AWSLogs/"
    }
  }
}