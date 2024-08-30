variable "db_name" {
    description = "database name"
    type = string
}

variable "db_username" {
    description = "The rds admin username"
    type        = string
    default     = "admin"
}

variable "instance_type" {
    description = "instance type"
    type = string
}

variable "vpc_remote_state_bucket" {
  description = "The name of the S3 bucket for the vpc's remote state"
  type        = string
}

variable "vpc_remote_state_key" {
  description = "The path for the vpc's remote state in S3"
  type        = string
}