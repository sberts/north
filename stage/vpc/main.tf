terraform {
    backend "s3" {
        bucket = "north-tf-state-usw2"
        key = "stage/vpc/terraform.tfstate"
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
            Module = "vpc"
            ManagedBy = "terraform"
            Environment = "stage"            
        }
    }
}

module "vpc" {
    source = "../../modules/vpc"
    vpc_name   = "stage-vpc"
    vpc_cidr = "10.224.0.0/16"
}
