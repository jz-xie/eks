variable "aws_region" {
  description = "AWS Region to be used that was defined in AWS CLI configuration"
  type        = string
}

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

variable "instances" {
  description = "EKS Cluster name"
  type        = map(any)
}
