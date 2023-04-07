variable "project" {
  description = "Name of your project/product/application"
  type        = string
}

variable "environment" {
  description = "Workspace environment: staging or production"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "eks_project_name" {
  description = "Project tag value of EKS Cluster"
  type        = string
}
