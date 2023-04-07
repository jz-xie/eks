terraform {
  required_providers {
    aws = {
      version = ">=4.59.0"
    }
  }
}

locals {
  bucket_name = "prefect-storage-${var.environment}"
}


module "s3" {
  source      = "git@github.com:jz-xie/python-mono.git//lib/terraform/s3"
  bucket_name = local.bucket_name
  required_tags = {
    Classification = "Internal"
    DataType       = "Uncategorized"
    Impact         = "Low"
  }
  additional_tags = {
    Name        = "bucket for prefect remote storage"
    project     = var.project
    environment = var.environment
  }
}

module "rds" {
  source                 = "git@github.com:jz-xie/python-mono.git//lib/terraform/rds"
  app                    = "prefect"
  environment            = var.environment
  cluster_name           = var.cluster_name
  aws_rds_engine_name    = "aurora-postgresql"
  aws_rds_engine_version = "14.6"
  instances = {
    one = {}
  }
  publicly_accessible    = true
  db_subnet_group_name   = "${var.cluster_name}-db-subnet-group"
  vpc_security_group_ids = data.aws_security_groups.this.ids
  rds_master_passwored   = jsondecode(data.aws_secretsmanager_secret_version.rds_secret.secret_string)["rds_master_password"]
}

