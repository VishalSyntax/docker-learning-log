# ==============================================================================
# Root Module - Docker Learning Lab Infrastructure Orchestration
# ==============================================================================

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Docker-Learning-Lab"
  }
}

# 1. Network Module: VPC, Public Subnet, Internet Gateway, and Route Table
module "network" {
  source             = "./modules/network"
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
  common_tags        = local.common_tags
}

# 2. Security Module: Security Group for SSH (22) and Docker service ports
module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  allowed_cidr = var.allowed_cidr
  common_tags  = local.common_tags
}

# 3. EC2 Module: Ubuntu 24.04 LTS instance, auto-generated SSH key, and user data bootstrap
module "ec2" {
  source                 = "./modules/ec2"
  project_name           = var.project_name
  instance_type          = var.instance_type
  public_subnet_id       = module.network.public_subnet_id
  security_group_id      = module.security.security_group_id
  user_data              = file("${path.module}/user_data.sh")
  existing_key_pair_name = var.existing_key_pair_name
  existing_key_path      = var.existing_key_path
  root_volume_size       = var.root_volume_size
  common_tags            = local.common_tags
}
