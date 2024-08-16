terraform {
    backend "s3" {
        bucket = "north-tf-state-usw2"
        key = "stage/mysql/terraform.tfstate"
        region = "us-west-2"
        dynamodb_table = "north-tf-locks"
        encrypt = true
    }
}

provider "aws" {
    region = "us-west-2"

    default_tags {
        tags = {
            Project = "north"
            Module = "mysql"
            ManagedBy = "terraform"
            Environment = "stage"            
        }
    }
}


module "mysql" {
    source = "../../../modules/data-stores/mysql"

    db_name = "mysql_stage"
    instance_type = "db.t3.micro"
}