# outputs.tf - All outputs

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = aws_subnet.main[*].id
}

# EC2 Outputs
output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.nginx.id
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = aws_eip.web_eip.public_ip
}

output "nginx_url" {
  description = "URL to access Nginx"
  value       = "http://${aws_eip.web_eip.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i keys/terraform-key ec2-user@${aws_eip.web_eip.public_ip}"
}

# AMI Output
output "ami_id" {
  description = "AMI ID used"
  value       = data.aws_ami.amazon_linux_2.id
}

output "ami_name" {
  description = "AMI name"
  value       = data.aws_ami.amazon_linux_2.name
}