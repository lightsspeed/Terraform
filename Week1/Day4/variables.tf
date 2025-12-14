# variables.tf - All variable definitions

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
  default     = 2

  validation {
    condition     = var.subnet_count > 0 && var.subnet_count <= 4
    error_message = "Subnet count must be between 1 and 4"
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t2.small", "t3.micro", "t3.small"], var.instance_type)
    error_message = "Instance type must be t2.micro, t2.small, t3.micro, or t3.small"
  }
}

variable "ssh_key_name" {
  description = "Name for SSH key pair"
  type        = string
  default     = "terraform-key"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "terraform-nginx"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "terraform-learning"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}