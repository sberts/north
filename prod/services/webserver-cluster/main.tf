provider "aws" {
    region = "us-west-2"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    cluster_name = "webservers-prod"
    db_remote_state_bucket = "north-tf-state-usw2"
    db_remote_state_key = "prod/services/webserver-cluster/terraform.tfstate"
}

resource "aws_autoscaling_schedule" "scale_out_during_business-hours" {
    scheduled_action_name = "scale-out-during-business-hours"
    min_size = 1
    max_size = 2
    desired_capacity = 1
    recurrence = "0 9 * * *"

    autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
    scheduled_action_name = "scale-in-at-night"
    min_size = 0
    max_size = 2
    desired_capacity = 0
    recurrence = "0 17 * * *"

    autoscaling_group_name = module.webserver_cluster.asg_name
}