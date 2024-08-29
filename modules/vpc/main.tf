locals {
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  app_subnets     = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets      = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 4)]
  db_subnets    = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 8)]
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  count = 3

  vpc_id     = aws_vpc.main.id
  cidr_block = local.public_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone = local.azs[count.index]
  
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_vpc.main.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_vpc.main.default_route_table_id

}

resource "aws_subnet" "app" {
  count = 3

  vpc_id     = aws_vpc.main.id
  cidr_block = local.app_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone = local.azs[count.index]
  
  tags = {
    Name = "app-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "db" {
  count = 3

  vpc_id     = aws_vpc.main.id
  cidr_block = local.db_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone = local.azs[count.index]
  
  tags = {
    Name = "db-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "app" {
  count          = 3
  subnet_id      = element(aws_subnet.app.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db" {
  count          = 3
  subnet_id      = element(aws_subnet.db.*.id, count.index)
  route_table_id = aws_route_table.private.id
}
