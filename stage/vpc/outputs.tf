output "vpc_id" {
    value = module.vpc.vpc_id
    description = "vpc id"
}

output "public_subnet_ids" {
    value = module.vpc.public_subnet_ids
    description = "public subnet ids"
}

output "private_subnet_ids" {
    value = module.vpc.private_subnet_ids
    description = "private subnet ids"
}

output "database_subnet_ids" {
    value = module.vpc.database_subnet_ids
    description = "database subnet ids"
}
