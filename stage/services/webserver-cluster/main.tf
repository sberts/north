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

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket used for the database's remote state storage"
  type        = string
  default = "north-tf-state-usw2"
}

variable "db_remote_state_key" {
  description = "The name of the key in the S3 bucket used for the database's remote state storage"
  type        = string
  default = "stage/mysql/terraform.tfstate"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    cluster_name = "webservers-stage"
    server_text = "server text"
    instance_type = "t4g.nano"
    min_size = 1
    max_size = 2

    db_remote_state_bucket = var.db_remote_state_bucket
    db_remote_state_key    = var.db_remote_state_key

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