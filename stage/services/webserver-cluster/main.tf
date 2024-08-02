terraform {
    backend "s3" {
        bucket = "north-tf-state-usw2"
        key = "stage/webserver-cluster/terraform.tfstate"
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
            Module = "webserver-cluster"
            ManagedBy = "terraform"
            Environment = "stage"            
        }
    }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "north-tf-state-usw2"
    key    = "stage/mysql/terraform.tfstate"
    region = "us-west-2"
  }
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    cluster_name = "webservers-stage"

    instance_type = "t4g.nano"
    min_size = 1
    max_size = 2
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
    enable_autoscaling = false
}

resource "aws_security_group_rule" "allow_inbound_ssh" {
    type = "ingress"
    security_group_id = module.webserver_cluster.alb_security_group_name

    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}