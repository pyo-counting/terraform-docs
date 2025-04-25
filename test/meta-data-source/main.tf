data "aws_arn" "db_instance" {
  arn = "arn:aws:rds:eu-west-1:123456789012:db:mysql-db"
}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_availability_zone" "available" {
  name = data.aws_availability_zones.available.names[0]
}

data "aws_caller_identity" "current" {}
