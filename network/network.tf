terraform {

}

provider "aws" {
  region = var.aws_region
}

locals {
  subnet_mask = var.subnet_mask
  az_num      = var.az_num
  cidr_block  = var.cidr_block
  # subnet_mask = 22
  # az_num      = 2
  # cidr_block  = "10.0.240.0/20"
  # subnet_mask       = 20
  # az_num            = 3
  # cidr_block        = "10.0.128.0/17"
  azs               = slice(data.aws_availability_zones.available.names, 0, local.az_num)
  subnet_type       = ["public", "private"]
  cidr_block_newbit = local.subnet_mask - tonumber(split("/", local.cidr_block)[1])
  cidrsubnets = cidrsubnets(local.cidr_block, [
    for i in range(local.az_num * length(local.subnet_type)) : local.cidr_block_newbit
  ]...)
  subnet_config = { for i, az in local.azs : az => [
    for j, type in local.subnet_type :
    {
      subnet_type       = type,
      cidr_block_subnet = slice(local.cidrsubnets, i * 2, (i + 1) * 2)[j]
    }
    ]
  }
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "create_subnets" {
  for_each            = local.subnet_config
  source              = "./network_config"
  availability_zone   = each.key
  subnets             = each.value
  project             = var.project
  aws_region          = var.aws_region
  environment         = var.environment
  cluster_name        = var.cluster_name
  vpc_id              = var.vpc_id
  igw_id              = var.igw_id
  private_subnet_tags = { "karpenter.sh/discovery" : true }
}


# Subnet Group for RDS
resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = [for subnets in values(module.create_subnets) : subnets["public_subnet_id"]]

  tags = {
    name        = "${var.cluster_name}/DBSubnetGroup"
    project     = var.project
    environment = var.environment
  }
}


# Security Group on Load Balancers for External IP
resource "aws_security_group" "elb_shared_security_group" {
  name   = "${var.cluster_name}/ELBSharedSecurityGroup"
  vpc_id = var.vpc_id

  ingress {
    description = "-"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}/ELBSharedSecurityGroup"
    project     = var.project
    environment = var.environment
  }
}
