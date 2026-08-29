# modules/vpc/variables.tf
variable "cidr_block" {
  type        = string
  description = "VPC CIDR Block"
}

variable "az" {
  type        = string
  description = "Availability Zone"
}
