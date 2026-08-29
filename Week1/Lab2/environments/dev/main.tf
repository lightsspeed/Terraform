module "vpc" {
  source              = "../../modules/vpc"
  cidr_block          = var.cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
  azs                 = var.azs
}

module "security_group" {
  source = "../../modules/security_group"
  vpc_id = module.vpc.vpc_id
}

module "asg_alb" {
  source            = "../../modules/asg_alb"
  environment       = "dev"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.subnet_ids
  security_group_id = module.security_group.security_group_id

  instance_type    = var.instance_type
  min_size         = 1
  max_size         = 2
  desired_capacity = 1
}
