output "vpc_id" {
    value = module.vpc.vpc_id
    description = "vpc id"
}

output "public_subnet_ids" {
    value = module.vpc.public_subnet_ids
    description = "public subnet ids"
}

output "app_subnet_ids" {
    value = module.vpc.app_subnet_ids
    description = "app subnet ids"
}

output "db_subnet_ids" {
    value = module.vpc.db_subnet_ids
    description = "db subnet ids"
}
