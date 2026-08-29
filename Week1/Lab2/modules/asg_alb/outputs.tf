output "alb_dns_name" {
  value       = aws_lb.web.dns_name
  description = "Public URL to access the Web Application Load Balancer"
}

output "asg_id" {
  value       = aws_autoscaling_group.web.id
  description = "Auto Scaling Group ID"
}

output "target_group_arn" {
  value       = aws_lb_target_group.web.arn
  description = "Target Group ARN"
}
