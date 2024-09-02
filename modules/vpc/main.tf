locals {
  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets    = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 4)]
  database_subnets     = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 8)]
  https_port     = 443
  tcp_protocol   = "tcp"
  any_port       = 0
  any_protocol   = "-1"
  all_ips = ["0.0.0.0/0"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  count = 3

  vpc_id     = aws_vpc.this.id
  cidr_block = local.public_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone = local.azs[count.index]
  
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_vpc.this.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_vpc.this.default_route_table_id

}

resource "aws_subnet" "private" {
  count = 3

  vpc_id     = aws_vpc.this.id
  cidr_block = local.private_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone = local.azs[count.index]
  
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "database" {
  count = 3

  vpc_id     = aws_vpc.this.id
  cidr_block = local.database_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone = local.azs[count.index]
  
  tags = {
    Name = "database-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count          = 3
  subnet_id      = element(aws_subnet.database.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.this.id
  subnet_ids = aws_subnet.public[*].id
  
  tags = {
    Name = "public_nacl"
  }
}

resource "aws_network_acl_rule" "public_http_inbound" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 100
  protocol       = "6" # 6 refers to TCP
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}
 
resource "aws_network_acl_rule" "public_ephemeral_outbound" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 210
  protocol       = "6" # 6 refers to TCP
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_icmp_outbound" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 220
  protocol       = "1" # 1 refers to ICMP
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 3  # dest unreach - frag needed
  icmp_code      = 4
}

resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.this.id
  subnet_ids = aws_subnet.private[*].id
  
  tags = {
    Name = "private_nacl"
  }
}

resource "aws_network_acl_rule" "private_http_inbound" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 100
  protocol       = "6" # 6 refers to TCP
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 8080
  to_port        = 8080
}

resource "aws_network_acl_rule" "private_ephemeral_inbound" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 110
  protocol       = "6" # 6 refers to TCP
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_icmp_inbound" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 120
  protocol       = "1" # 1 refers to ICMP
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 3
  icmp_code      = 4
}

resource "aws_network_acl_rule" "private_https_outbound" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 200
  protocol       = "6"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}
 
resource "aws_network_acl_rule" "private_ephemeral_outbound" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 210
  protocol       = "6" # 6 refers to TCP
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_icmp_outbound" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 220
  protocol       = "1" # 1 refers to ICMP
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 3  # dest unreach - frag needed
  icmp_code      = 4
}


resource "aws_network_acl" "database_nacl" {
  vpc_id = aws_vpc.this.id
  subnet_ids = aws_subnet.database[*].id
  
  tags = {
    Name = "database_nacl"
  }
}

resource "aws_network_acl_rule" "database_mysql_inbound" {
  network_acl_id = aws_network_acl.database_nacl.id
  rule_number    = 100
  protocol       = "6" # 6 refers to TCP
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 3306
  to_port        = 3306
}
 
resource "aws_network_acl_rule" "database_ephemeral_outbound" {
  network_acl_id = aws_network_acl.database_nacl.id
  rule_number    = 210
  protocol       = "6" # 6 refers to TCP
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "database_icmp_outbound" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 220
  protocol       = "1" # 1 refers to ICMP
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 3  # dest unreach - frag needed
  icmp_code      = 4
}

resource "aws_security_group" "vpc_endpoint" {
  name = "vpc endpoint"
  vpc_id = aws_vpc.this.id
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
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.us-west-2.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true

  tags = {
    Name = "ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.us-west-2.s3"
  vpc_endpoint_type = "Gateway"
  
  route_table_ids = [ aws_route_table.private.id ]

  tags = {
    Name = "s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id       = aws_vpc.this.id
  subnet_ids        = aws_subnet.private[*].id
  service_name      = "com.amazonaws.us-west-2.ec2messages"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true
  tags = {
    Name = "ec2messages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id       = aws_vpc.this.id
  subnet_ids        = aws_subnet.private[*].id
  service_name      = "com.amazonaws.us-west-2.ssmmessages"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true
  tags = {
    Name = "ssmmessages-endpoint"
  }
}