variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "az" {
  type = string
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type"
}

variable "ebs_size" {
  type        = number
  default     = 40
  description = "EBS volume size in GiB"
}

variable "ami_owner" {
  type        = string
  default     = "099720109477"
  description = "Owner ID for the AMI lookup"
}

variable "ami_name_filter" {
  type        = string
  default     = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
  description = "Name filter pattern for AMI lookup"
}

variable "ssh_key_name" {
  type        = string
  default     = "deployer-key"
  description = "Name of the SSH key pair"
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/aws_deployer_key.pub"
  description = "Path to the SSH public key file"
}

variable "ebs_device_name" {
  type        = string
  default     = "/dev/sdh"
  description = "Device name for EBS volume attachment"
}

variable "instance_name" {
  type        = string
  default     = "HelloWorld"
  description = "Name tag for EC2 instance and EBS volume"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to apply to resources"
}

variable "associate_public_ip" {
  type        = bool
  default     = true
  description = "Whether to associate a public IP address with the instance"
}
