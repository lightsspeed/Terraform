output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the created VPC"
  value       = aws_vpc.main.cidr_block
}

output "igw_id" {
  description = "The ID of the created Internet Gateway"
  value       = aws_internet_gateway.gw.id
}

output "subnet_ids" {
  description = "The IDs of the created Subnets"
  value       = aws_subnet.main[*].id
}

output "subnet_cidrs" {
  description = "The CIDR blocks of the created Subnets"
  value       = aws_subnet.main[*].cidr_block
}

output "subnet_azs" {
  description = "The Availability Zones of the created Subnets"
  value       = aws_subnet.main[*].availability_zone
}

output "route_table_id" {
  description = "The ID of the created Route Table"
  value       = aws_route_table.routetable.id
}

output "route_table_association_ids" {
  description = "The IDs of the created Route Table Associations"
  value       = aws_route_table_association.main[*].id # ✅ Fixed: Use count reference
}