resource "aws_vpc" "main" {
  cidr_block           = "172.27.0.0/19"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "main" {
  for_each = {
    pri-1 = {
      az         = "ap-northeast-2a"
      cidr_block = "172.27.0.0/21"
    }
    pri-2 = {
      az         = "ap-northeast-2b"
      cidr_block = "172.27.8.0/21"
    }
    pub = {
      az         = "ap-northeast-2a"
      cidr_block = "172.27.16.0/21"
    }
  }

  availability_zone                           = each.value.az
  cidr_block                                  = each.value.cidr_block
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = false
  private_dns_hostname_type_on_launch         = "resource-name"
  vpc_id                                      = aws_vpc.main.id
}

resource "aws_eip" "main" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  connectivity_type = "public"
  allocation_id     = aws_eip.main.id
  subnet_id         = aws_subnet.main["pub"].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "pri-1" {
  subnet_id      = aws_subnet.main["pri-1"].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "pri-2" {
  subnet_id      = aws_subnet.main["pri-2"].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "pub" {
  subnet_id      = aws_subnet.main["pub"].id
  route_table_id = aws_route_table.public.id
}