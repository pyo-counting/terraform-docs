data "aws_region" "current" {}

locals {
  # provider
  region    = "ap-northeast-2"
  profile = "playground"
  
  corp        = "psy"
  environment = "playground"
  product     = "test"
}