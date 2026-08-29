# modules/vpc/variables.tf
variable "cidr_block" {
  type        = string
  description = "VPC CIDR Block"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets (minimum 2 for ALB)"
}

variable "azs" {
  type        = list(string)
  description = "List of Availability Zones (minimum 2 for ALB)"
}
