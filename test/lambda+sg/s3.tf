module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.2"

  bucket        = format("%s-%s-%s-s3", local.corp, local.environment, local.product)
  create_bucket = true
  force_destroy = true
  # bucket policy
  attach_policy                  = false
  attach_elb_log_delivery_policy = false
  policy                         = ""
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
        days = 1 # 1d
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
  versioning                = { enabled = false }
  replication_configuration = {}
  tags                      = { Name = format("%s-%s-%s-s3", local.corp, local.environment, local.product) }
}
