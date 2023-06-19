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

variable "rds_id" {
  description = "RDS Cluster Identifier"
  type        = string
}

variable "web_url" {
  description = "Web URL for Superset"
  type        = string
}

variable "update_docker_image" {
  description = "Whether updates the docker image"
  type        = bool
  default     = false
}
variable "app_name" {
  description = "Name of applucation"
  type        = string
}

variable "domain_cert_arn" {
  description = "Certificate ARN for web domain"
  type        = string
}

variable "repository" {
  description = "Docker repository for Superset"
  type        = string
}
