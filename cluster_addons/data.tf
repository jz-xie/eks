locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_num)
}

data "aws_route53_zone" "selected" {
  name = local.eks_cluster_domain
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_ami" "eks" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-${data.aws_eks_cluster.this.version}-*"]
  }
}

data "aws_ami" "bottlerocket" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${data.aws_eks_cluster.this.version}-x86_64-*"]
  }
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "kubectl_path_documents" "karpenter_provisioners" {
  pattern = "${path.module}/karpenter_provisioners/*.yaml" # without launch template
  vars = {
    azs                     = join(",", local.azs)
    iam-instance-profile-id = "${var.cluster_name}-${local.node_group_name}"
    eks-cluster-id          = var.cluster_name
    eks-vpc-name            = var.cluster_name
  }
}


data "aws_security_group" "worker_node_security_group" {
  tags = {
    Name = "${var.cluster_name}-node"
  }
}
