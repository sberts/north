variable "vpc_name" {
    description = "The VPC name"
    type        = string
    default     = "vpc"
}

variable "vpc_cidr" {
    description = "The VPC CIDR"
    type = string
}
