variable "aws_region" {
  description = "AWS Region to be used that was defined in AWS CLI configuration"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Name of your project/product/application"
  type        = string
  default     = "eks"
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

variable "subnet_mask" {
  description = "Subnet CIDR Block Mask"
  type        = number
  default     = 22
}

variable "az_num" {
  description = "Number of Subnet Availability Zones"
  type        = number
  default     = 2
}

variable "cidr_block" {
  description = "CIDR Block in which Subnets are Created"
  type        = string
  default     = "10.0.240.0/20"
}

variable "vpc_id" {
  type = string
}


variable "igw_id" {
  type = string
}
