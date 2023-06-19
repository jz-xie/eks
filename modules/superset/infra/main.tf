terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


module "rds" {
  source                 = "git@github.com:jz-xie/terraform-helper.git//rds"
  app                    = var.project
  environment            = var.environment
  cluster_name           = var.cluster_name
  aws_rds_engine_name    = "aurora-postgresql"
  aws_rds_engine_version = "15.2"
  instances              = var.instances
  publicly_accessible    = true
  db_subnet_group_name   = "${var.cluster_name}-db-subnet-group"
  vpc_security_group_ids = data.aws_security_groups.this.ids
  rds_master_passwored   = jsondecode(data.aws_secretsmanager_secret_version.rds_secret.secret_string)["rds_master_password"]
}

