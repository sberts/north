variable "db_username" {
    description = "the username for the database"
    type = string
    sensitive = true
}

variable "db_password" {
    description = "the password for the database"
    type = string
    sensitive = true
}