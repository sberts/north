
provider "aws" {
    region = "us-west-2"
}

resource "aws_db_instance" "north" {
    engine = "mysql"
    allocated_storage = 10
    instance_class = var.instance_type
    skip_final_snapshot = true
    db_name = var.db_name

    username = var.db_username
    password = var.db_password
}