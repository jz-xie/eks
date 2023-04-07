terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }

    kubernetes = {
      version = ">=2.16.0"
    }

    helm = {
      version = ">=2.8.0"
    }
  }
}

resource "helm_release" "prefect_server" {
  name             = "prefect-server"
  repository       = "prefect/prefect-server"
  chart            = "prefect/prefect-server"
  version          = "2023.03.02"
  namespace        = "prefect"
  create_namespace = true
  values = [
    "${file("${path.module}/prefect-server.yaml")}"
  ]

  set {
    name  = "postgresql.useSubChart"
    value = false
  }

  set {
    name  = "postgresql.auth.username"
    value = data.aws_rds_cluster.this.master_username
  }
  set {
    name  = "postgresql.auth.database"
    value = data.aws_rds_cluster.this.database_name
  }
  set_sensitive {
    name  = "postgresql.auth.password"
    value = jsondecode(data.aws_secretsmanager_secret_version.rds_secret.secret_string)["rds_master_password"]
  }
  set {
    name  = "postgresql.externalHostname"
    value = data.aws_rds_cluster.this.endpoint
  }
}


resource "helm_release" "prefect_agent" {
  name             = "prefect-agent"
  repository       = "prefect/prefect-agent"
  chart            = "prefect/prefect-agent"
  version          = "2023.03.02"
  namespace        = "prefect"
  create_namespace = true
  values = [
    "${file("${path.module}/prefect-agent.yaml")}"
  ]
}
