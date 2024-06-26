################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = try(one(aws_vpc.this).id, null)
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = try(one(aws_vpc.this).cidr_block, null)
}

################################################################################
# Subnets
################################################################################

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = compact(aws_subnet.private[*].cidr_block)
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = compact(aws_subnet.public[*].cidr_block)
}

################################################################################
# Internet Gateway
################################################################################

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = try(one(aws_internet_gateway.this).id, null)
}

################################################################################
# NAT Gateway
################################################################################

output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat[*].id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat[*].public_ip
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

################################################################################
# Route Tables
################################################################################

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = try(aws_route_table.private[*].id, null)
}
output "public_route_table_id" {
  description = "The ID of the Public Route Table"
  value       = try(one(aws_route_table.public).id, null)
}

################################################################################
# Network ACLs
################################################################################

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = try(one(aws_network_acl.private).id, null)
}

output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = try(one(aws_network_acl.public).id, null)
}
