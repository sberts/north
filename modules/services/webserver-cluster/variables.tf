variable "cluster_name" {
    description = "The name to use for all the cluster resources"
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

variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
  type = bool
}

variable "instance_type" {
    description = "The type of EC2 Instance to run (e.g. t2.micro)"
    type = string
    default = "t2.micro"
}

variable "ami" {
  description = "the ami to run in the cluster"
  type = string
  default = "ami-02d3770deb1c746ec"
}

variable "server_text" {
  description = "the text the web server should return"
  type = string
  default = "hello world"
}

variable "remote_state_bucket" {
  description = "The name of the S3 bucket for the remote state"
  type        = string
}

variable "vpc_remote_state_key" {
  description = "The path for the vpc's remote state in S3"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
}