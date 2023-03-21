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


locals {
  tags = {
    project     = var.project
    environment = var.environment
    github_repo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
  # AWS Route 53
  eks_cluster_domain = "sample_domain.com"
  node_group_name    = "main"
}



#---------------------------------------------------------------
# EKS Blueprints Add-ons
#---------------------------------------------------------------

module "eks_blueprints_kubernetes_addons" {
  source = "git@github.com:aws-ia/terraform-aws-eks-blueprints.git//modules/kubernetes-addons"

  eks_cluster_id       = data.aws_eks_cluster.this.id
  eks_cluster_endpoint = data.aws_eks_cluster.this.endpoint
  eks_oidc_provider    = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  eks_cluster_version  = data.aws_eks_cluster.this.version
  eks_cluster_domain   = local.eks_cluster_domain

  # enable_argocd = true
  # argocd_applications = {
  #   workloads = {
  #     path               = "envs/dev"
  #     repo_url           = "https://github.com/aws-samples/eks-blueprints-workloads.git"
  #     target_revision    = "main"
  #     add_on_application = false
  #     values = {
  #       spec = {
  #         source = {
  #           repoURL        = "https://github.com/aws-samples/eks-blueprints-workloads.git"
  #           targetRevision = "main"
  #         }
  #         blueprint   = "terraform"
  #         clusterName = module.eks_blueprints.eks_cluster_id
  #         env         = "dev"
  #         ingress = {
  #           type           = "alb"
  #           host           = var.eks_cluster_domain
  #           route53_weight = "100" # <-- You can control the weight of the route53 weighted records between clusters
  #         }
  #       }
  #     }
  #   }
  # }

  # enable_ingress_nginx = true
  # ingress_nginx_helm_config = {
  #   values = [templatefile("${path.module}/nginx-values.yaml", {
  #     hostname     = local.eks_cluster_domain
  #     ssl_cert_arn = data.aws_acm_certificate.issued.arn
  #   })]
  # }

  enable_karpenter = true

  # enable_cluster_autoscaler = true

  enable_aws_node_termination_handler = true

  enable_amazon_eks_aws_ebs_csi_driver = true

  enable_aws_load_balancer_controller = true

  enable_external_dns = true
  external_dns_helm_config = {
    values = [templatefile("${path.module}/external_dns-values.yaml", {
      txtOwnerId   = data.aws_route53_zone.selected.zone_id
      zoneIdFilter = local.eks_cluster_domain
    })]
  }

  tags = local.tags

  # depends_on = [
  #   module.eks_blueprints
  # ]
}
