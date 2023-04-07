# provider "aws" {
#   region = var.aws_region
# }

# provider "kubernetes" {
#   host                   = module.eks_blueprints.eks_cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.this.token
# }

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.72"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
  }
}
