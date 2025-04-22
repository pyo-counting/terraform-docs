module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws//wrappers"
  version = "3.15.2"

  defaults = {
    create_bucket = true
  }
  items = {
    test = {
      bucket        = format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "test")
      force_destroy = false
      # bucket policy
      attach_policy                  = true
      attach_elb_log_delivery_policy = false
      policy = jsonencode(
        {
          Statement = [
            {
              Effect = "Deny"
              Principal = "*"
              Action = "s3:PutObject"
              Resource = [
                "arn:aws:s3:::${format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "test")}/*",
                "arn:aws:s3:::${format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "test")}"
              ]
            }
          ]
        }
      )
      # public access policy
      attach_public_policy    = true
      block_public_policy     = true
      block_public_acls       = true
      ignore_public_acls      = true
      restrict_public_buckets = true
      # bucket config
      intelligent_tiering                  = {}
      lifecycle_rule                       = [
        {
          id      = "periodic-expiration"
          enabled = true
          expiration = {
            days = 365 # 1y
          }
        }
      ]
      logging                              = {}
      metric_configuration                 = []
      server_side_encryption_configuration = {}
      tags                                 = { name = format("%s-%s-%s-s3-%s", local.corp, local.environment, local.product, "test") }
      versioning                           = {}
    }
  }
}