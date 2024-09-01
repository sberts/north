locals {
  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  app_subnets    = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 4)]
  db_subnets     = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 8)]
  https_port = 80
  tcp_protocol = "tcp"
  any_port = 0
  any_protocol = "-1"

  all_ips = ["0.0.0.0/0"]
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

resource "aws_security_group" "vpc_endpoint" {
  name = "vpc endpoint"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "allow_https_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.vpc_endpoint.id

  from_port = local.https_port
  to_port   = local.https_port
  protocol  = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.vpc_endpoint.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.app[*].id
  security_group_ids = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true

  tags = {
    Name = "ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-west-2.s3"
  vpc_endpoint_type = "Gateway"
  
  route_table_ids = [ aws_route_table.private.id ]

  tags = {
    Name = "s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id       = aws_vpc.main.id
  subnet_ids        = aws_subnet.app[*].id
  service_name      = "com.amazonaws.us-west-2.ec2messages"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true
  tags = {
    Name = "ec2messages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id       = aws_vpc.main.id
  subnet_ids        = aws_subnet.app[*].id
  service_name      = "com.amazonaws.us-west-2.ssmmessages"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true
  tags = {
    Name = "ssmmessages-endpoint"
  }
}