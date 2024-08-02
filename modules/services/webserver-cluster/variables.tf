variable "cluster_name" {
    description = "The name to use for all the cluster resources"
    type = string
}

variable "instance_type" {
    description = "The type of EC2 Instance to run (e.g. t2.micro)"
    type = string
}

variable "min_size" {
    description = "The minimum number of EC2 Instances in the ASG"
    type = number
}

variable "max_size" {
    description = "The maximum number of EC2 Instances in the ASG"
    type = number
}

variable "db_address" {
  description = "The address of the RDS instance"
  type        = string
}

variable "db_port" {
  description = "The port of the RDS instance"
  type        = number
}

variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
  type = bool
}