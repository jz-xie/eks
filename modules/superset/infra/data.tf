data "aws_secretsmanager_secret" "rds_secret" {
  name = "${var.project}/${var.environment}"
}

data "aws_secretsmanager_secret_version" "rds_secret" {
  secret_id = data.aws_secretsmanager_secret.rds_secret.id
}

data "aws_security_groups" "this" {
  tags = {
    project     = "bigdata-eks"
    environment = var.environment
  }
}
