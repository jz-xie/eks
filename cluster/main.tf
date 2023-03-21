terraform {

}

# provider "aws" {
#   region = var.aws_region
# }

locals {
  tags = {
    project     = var.project
    environment = var.environment
    github_repo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

module "eks_blueprints" {
  source = "git@github.com:aws-ia/terraform-aws-eks-blueprints.git"

  cluster_name    = var.cluster_name
  cluster_version = "1.24"

  vpc_id                    = var.vpc_id
  private_subnet_ids        = data.aws_subnets.private.ids
  public_subnet_ids         = data.aws_subnets.public.ids
  enable_cluster_encryption = true

  # "Determines if a security group is created for the cluster. 
  # Note: the EKS service creates a primary security group for the cluster by default"
  # create_cluster_security_group = false

  #----------------------------------------------------------------------------------------------------------#
  # Security groups used in this module created by the upstream modules terraform-aws-eks (https://github.com/terraform-aws-modules/terraform-aws-eks).
  #   Upstream module implemented Security groups based on the best practices doc https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html.
  #   So, by default the security groups are restrictive. Users needs to enable rules for specific ports required for App requirement or Add-ons
  #   See the notes below for each rule used in these examples
  #----------------------------------------------------------------------------------------------------------#
  node_security_group_additional_rules = {
    # Extend node-to-node security group rules. Recommended and required for the Add-ons
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Recommended outbound traffic for Node groups
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    # Allows Control Plane Nodes to talk to Worker nodes on all ports. Added this to simplify the example and further avoid issues with Add-ons communication with Control plane.
    # This can be restricted further to specific port based on the requirement for each Add-on e.g., metrics-server 4443, spark-operator 8080, karpenter 8443 etc.
    # Change this according to your security requirements if needed

    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }

    # # Allows Control Plane Nodes to talk to Worker nodes on Karpenter ports.
    # # This can be extended further to specific port based on the requirement for others Add-on e.g., metrics-server 4443, spark-operator 8080, etc.
    # # Change this according to your security requirements if needed
    # ingress_nodes_karpenter_port = {
    #   description                   = "Cluster API to Nodegroup for Karpenter"
    #   protocol                      = "tcp"
    #   from_port                     = 8443
    #   to_port                       = 8443
    #   type                          = "ingress"
    #   source_cluster_security_group = true
    # }
  }

  # Add karpenter.sh/discovery tag so that we can use this as securityGroupSelector in karpenter provisioner
  node_security_group_tags = {
    "karpenter.sh/discovery/${var.cluster_name}" = var.cluster_name
  }

  managed_node_groups = {
    mg_5 = {
      node_group_name = var.node_group_name
      instance_types  = ["m5.large", "m5a.large", "m5n.large", "m6a.large"]
      min_size        = 1
      max_size        = 8
      desired_size    = 2

      update_config = [{
        max_unavailable_percentage = 50
      }]

      subnet_ids = data.aws_subnets.private.ids
    }
  }

  tags = local.tags

  # depends_on = [
  #   module.create_subnets
  # ]
}

# Allow Security Group of AWS Managed Node Group Ingress from Worker Node Group
resource "aws_security_group_rule" "primary_security_group_ingress_from_worker" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  security_group_id        = module.eks_blueprints.cluster_primary_security_group_id
  source_security_group_id = module.eks_blueprints.worker_node_security_group_id

  depends_on = [
    module.eks_blueprints
  ]
}

resource "aws_security_group_rule" "worker_ingress_from_primary_security_group" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  security_group_id        = module.eks_blueprints.worker_node_security_group_id
  source_security_group_id = module.eks_blueprints.cluster_primary_security_group_id

  depends_on = [
    module.eks_blueprints
  ]
}
