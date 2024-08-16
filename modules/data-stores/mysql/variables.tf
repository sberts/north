variable "db_name" {
    description = "database name"
    type = string
}

variable "db_secret" {
    description = "The name of the secret that has the db admin username/password"
    type        = string
    default     = "north-db-password"
}

variable "instance_type" {
    description = "instance type"
    type = string
}
