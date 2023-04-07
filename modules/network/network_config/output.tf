output "public_subnet_id" {
  value = aws_subnet.subnets["public"].id
}
output "private_subnet_id" {
  value = aws_subnet.subnets["private"].id
}
