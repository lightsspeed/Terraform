variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where ASG and ALB will be created"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of Subnet IDs for ALB and ASG"
}

variable "security_group_id" {
  type        = string
  description = "Security Group ID"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for Launch Template"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum size of Auto Scaling Group"
}

variable "max_size" {
  type        = number
  default     = 3
  description = "Maximum size of Auto Scaling Group"
}

variable "desired_capacity" {
  type        = number
  default     = 1
  description = "Desired capacity of Auto Scaling Group"
}
