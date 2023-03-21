variable "availability_zone" {
  type = string
}

variable "subnets" {
  type = list(object({
    subnet_type       = string
    cidr_block_subnet = string
  }))
}

variable "vpc_id" {
  type = string
}

variable "igw_id" {
  description = "Internet Gateway ID of the VPC"
  type        = string
}


variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "environment" {
  description = "Workspace environment: staging or production"
  type        = string
}

variable "project" {
  description = "Name of your project/product/application"
  type        = string
}

variable "aws_region" {
  description = "AWS Region to be used that was defined in AWS CLI configuration"
  type        = string
}

variable "private_subnet_tags" {
  description = "Tags for Private Subnets"
  type        = map(any)
}

