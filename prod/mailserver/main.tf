variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

provider "aws" {
  region = "us-west-2"
}

resource "tls_private_key" "north" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "north" {
  key_name   = "north-key"
  public_key = tls_private_key.north.public_key_openssh
}

resource "aws_security_group" "mailserver" {
  name = "north sg"

  ingress {
    from_port = var.server_port
    to_port   = var.server_port
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["76.95.238.167/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#resource "aws_instance" "mailserver" {
#  ami                         = "ami-05af537b78f07c4f7"
#  instance_type               = "t4g.nano"
#  vpc_security_group_ids      = [aws_security_group.mailserver.id]
#  key_name                    = aws_key_pair.north.key_name
#  user_data_replace_on_change = true

#  tags = {
#    Name = "mailserver"
#  }

#  user_data = <<-EOF
#    #!/bin/bash
#    yum install -y nginx
#    sed -i s/80/${var.server_port}/g /etc/nginx/nginx.conf
#    systemctl start nginx
#    EOF
#}

output "private_key_pem" {
  value     = tls_private_key.north.private_key_pem
  sensitive = true
}

#output "instance_public_ip" {
#  value = aws_instance.mailserver.public_ip
#}