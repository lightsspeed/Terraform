variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR block"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "List of public subnet CIDR blocks (min 2 for ALB)"
}

variable "azs" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "List of Availability Zones (min 2 for ALB)"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for the EC2 instance"
}
