output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = aws_subnet.main[*].id
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.nginx.id
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = aws_eip.web_eip.public_ip
}

output "nginx_url" {
  description = "Nginx URL"
  value       = "http://${aws_eip.web_eip.public_ip}"
}

output "ssh_command" {
  description = "SSH command"
  value       = "ssh -i keys/terraform-key ec2-user@${aws_eip.web_eip.public_ip}"
}