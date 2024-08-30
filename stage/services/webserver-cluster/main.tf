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

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    cluster_name = "webservers-stage"
    server_text = "server text"
    instance_type = "t4g.nano"
    min_size = 1
    max_size = 2

    remote_state_bucket  = var.remote_state_bucket
    vpc_remote_state_key = var.vpc_remote_state_key
    db_remote_state_key  = var.db_remote_state_key

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