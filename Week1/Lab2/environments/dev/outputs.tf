output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the Dev VPC"
}

output "subnet_ids" {
  value       = module.vpc.subnet_ids
  description = "The IDs of the Dev public subnets"
}

output "security_group_id" {
  value       = module.security_group.security_group_id
  description = "The ID of the Dev Security Group"
}

output "alb_dns_name" {
  value       = module.asg_alb.alb_dns_name
  description = "Public URL to access the Dev Web Application Load Balancer"
}

output "asg_id" {
  value       = module.asg_alb.asg_id
  description = "Dev Auto Scaling Group ID"
}
