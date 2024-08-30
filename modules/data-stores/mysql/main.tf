

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.vpc_remote_state_bucket
    key    = var.vpc_remote_state_key
    region = "us-west-2"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main-subnet-group"
  subnet_ids = data.terraform_remote_state.vpc.outputs.db_subnet_ids

  tags = {
    Name = "${var.db_name} subnet group"
  }
}

resource "aws_security_group" "main" {
  name        = var.db_name
  description = "db sg"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = var.db_name
  }
}

resource "aws_db_instance" "north" {
    engine = "mysql"
    engine_version = "8.0"
    allocated_storage = 10
    instance_class = var.instance_type
    skip_final_snapshot = true
    db_name = var.db_name
    identifier = "north"
    username = var.db_username
    manage_master_user_password = true
    db_subnet_group_name = aws_db_subnet_group.main.name
    vpc_security_group_ids = [ aws_security_group.main.id ]

    tags = {
        Name = var.db_name
    }
}