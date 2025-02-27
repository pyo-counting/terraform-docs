data "aws_arn" "db_instance" {
  arn = "arn:aws:rds:eu-west-1:123456789012:db:mysql-db"
}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}