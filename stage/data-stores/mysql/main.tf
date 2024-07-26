terraform {
    backend "s3" {
        bucket = "north-tf-state-usw2"
        key = "stage/data-stores/mysql/terraform.tfstate"
        region = "us-west-2"
        dynamodb_table = "north-tf-locks"
        encrypt = true
    }
}

provider "aws" {
    region = "us-west-2"
}

resource "aws_db_instance" "north" {
    identifier_prefix = "north"
    engine = "mysql"
    allocated_storage = 10
    instance_class = "db.t3.micro"
    skip_final_snapshot = true
    db_name = "north"

    username = var.db_username
    password = var.db_password
}