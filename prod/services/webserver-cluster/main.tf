provider "aws" {
    region = "us-west-2"

    default_tags {
        tags = {
            Project = "north"
            ManagedBy = "terraform"
            Environment = "prod"            
        }
    }
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    cluster_name = "webservers-prod"
    db_remote_state_bucket = "north-tf-state-usw2"
    db_remote_state_key = "prod/services/webserver-cluster/terraform.tfstate"
    enable_autoscaling = true
}

