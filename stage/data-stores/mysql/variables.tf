variable "vpc_remote_state_bucket" {
  description = "The name of the S3 bucket used for the vpc's remote state storage"
  type        = string
  default = "north-tf-state-usw2"
}

variable "vpc_remote_state_key" {
  description = "The name of the key in the S3 bucket used for the vpc's remote state storage"
  type        = string
  default = "stage/vpc/terraform.tfstate"
}
