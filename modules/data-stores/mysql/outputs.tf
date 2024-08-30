output "address" {
    value = aws_db_instance.north.address
    description = "Connect to the database at this endpoint"
}

output "port" {
    value = aws_db_instance.north.port
    description = "The port the database is listening on"
}

output "sg_id" {
    value = aws_security_group.main.id
    description = "The db secgroup id"
}