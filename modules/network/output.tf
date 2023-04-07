output "subnets" {
  value       = local.subnet_config
  description = "Subnet config with AZ, CIDR Block and Type (Public/Private)"
}
