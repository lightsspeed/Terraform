output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs (for use with ALB and ASG)"
}
