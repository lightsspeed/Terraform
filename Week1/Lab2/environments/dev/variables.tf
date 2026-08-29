variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "az" {
  type        = list(string)
  default     = ["us-east-1a"]
  description = "List of Availability Zones"
}

variable "cidr_block" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "List of VPC CIDR blocks"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for the EC2 instance"
}
