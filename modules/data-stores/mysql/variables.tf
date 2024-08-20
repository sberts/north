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
