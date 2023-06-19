terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
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

resource "null_resource" "build_push_docker" {
  count = var.update_docker_image ? 1 : 0
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command     = "/bin/bash build_push_ecr.sh"
    working_dir = abspath("docker")
    environment = {
      ECR_REPO = "bigdata-superset"
      TAG      = var.environment
      REGION   = var.aws_region
    }
  }
}

locals {
  ingress = <<EOT
    alb.ingress.kubernetes.io/security-groups: ${join("\\,", data.aws_security_groups.this.ids)}
    external-dns.alpha.kubernetes.io/hostname: ${var.web_url}
  path: /
  pathType: Prefix
  hosts:
    [${var.web_url}]
  tls: []
  extraHostsRaw: []
EOT
}

resource "helm_release" "superset" {
  name             = "superset"
  repository       = "superset/superset"
  chart            = "superset/superset"
  version          = "0.10.1"
  namespace        = "superset"
  create_namespace = true
  values = [
    "${file("${path.module}/values.yaml")}"
  ]


  set {
    name  = "postgresql.enabled"
    value = false
  }
  set {
    name  = "supersetNode.connections.db_user"
    value = data.aws_rds_cluster.this.master_username
  }
  set {
    name  = "supersetNode.connections.db_name"
    value = data.aws_rds_cluster.this.database_name
  }
  set_sensitive {
    name  = "supersetNode.connections.db_pass"
    value = replace(replace(jsondecode(data.aws_secretsmanager_secret_version.rds_secret.secret_string)["rds_master_password"], "\\", "\\\\"), ",", "\\,")
    type  = "string"
  }
  set {
    name  = "supersetNode.connections.db_host"
    value = data.aws_rds_cluster.this.endpoint
  }

  set_sensitive {
    name  = "extraSecretEnv.SUPERSET_APP_SECRET_KEY"
    value = jsondecode(data.aws_secretsmanager_secret_version.rds_secret.secret_string)["app_secret_key"]
  }

  set_sensitive {
    name  = "extraSecretEnv.SUPERSET_AWS_COGNITO_CLIENT_SECRET"
    value = jsondecode(data.aws_secretsmanager_secret_version.rds_secret.secret_string)["aws_cognito_client_secret"]
  }

  set {
    name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/security-groups"
    value = join("\\,", data.aws_security_groups.this.ids)
  }
  set {
    name  = "ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = var.web_url
  }
  set {
    name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = var.domain_cert_arn
  }
  set {
    name  = "ingress.hosts"
    value = "{${var.web_url}}"
  }
  set {
    name  = "image.tag"
    value = var.environment
  }
  set {
    name  = "image.repository"
    value = var.repository
  }
  set {
    name  = "configOverrides.my_overrides"
    value = replace(replace(file("${path.module}/my_superset_config.py"), "\\", "\\\\"), ",", "\\,")
    type  = "string"
  }
  set {
    name  = "extraEnv.APP_NAME"
    value = var.app_name
  }
}

output "values" {
  value = helm_release.superset.metadata
}
