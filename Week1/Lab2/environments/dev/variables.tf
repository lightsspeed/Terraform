variable "region" {
  type        = string
  description = "AWS Region"
}

variable "az" {
  type        = list(string)
  description = "List of Availability Zones"
}

variable "cidr_block" {
  type        = list(string)
  description = "List of VPC CIDR blocks"
}


variable "instance_type" {
  type        = string
  description = "Instance type for the EC2 instance"
  default     = "t3.micro"
}
