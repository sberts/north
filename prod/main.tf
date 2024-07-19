provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "mailserver" {
  ami = "ami-05af537b78f07c4f7"
  instance_type = "t4g.nano"
  tags = {
    Name = "mailserver"
  }
}

