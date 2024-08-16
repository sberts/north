data "aws_secretsmanager_secret" "db_secret" {
  name = var.db_secret
}

data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}

data "aws_secretsmanager_secret_version" "db_secret" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}

locals {
  db_username = jsondecode(data.aws_secretsmanager_secret_version.db_secret.secret_string)["username"]
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_secret.secret_string)["password"]
}

resource "aws_db_instance" "north" {
    engine = "mysql"
    allocated_storage = 10
    instance_class = var.instance_type
    skip_final_snapshot = true
    db_name = var.db_name

    username = local.db_username
    password = local.db_password
}