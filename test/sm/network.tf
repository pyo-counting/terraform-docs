resource "aws_vpc" "main" {
  cidr_block           = "172.28.0.0/19"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "main" {
  for_each = {
    pri_1 = {
      az         = "ap-northeast-2a"
      cidr_block = "172.28.0.0/21"
    }
    pri_2 = {
      az         = "ap-northeast-2c"
      cidr_block = "172.28.8.0/21"
    }
  }

  availability_zone                           = each.value.az
  cidr_block                                  = each.value.cidr_block
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = false
  private_dns_hostname_type_on_launch         = "ip-name"
  vpc_id                                      = aws_vpc.main.id
}