resource "aws_db_instance" "north" {
    engine = "mysql"
    engine_version = "8.0"
    allocated_storage = 10
    instance_class = var.instance_type
    skip_final_snapshot = true
    db_name = var.db_name
    identifier = "north"
    username = var.db_username
    manage_master_user_password = true
}