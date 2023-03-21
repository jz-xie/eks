variable "aws_region" {
  description = "AWS Region to be used that was defined in AWS CLI configuration"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Name of your project/product/application"
  type        = string
}

variable "environment" {
  description = "Workspace environment: staging or production"
  type        = string
  default     = "staging"
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "az_num" {
  description = "Number of Subnet Availability Zones"
  type        = number
  default     = 2
}

variable "node_group_name" {
  type    = string
  default = "main"
}
