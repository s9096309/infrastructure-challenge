# terraform/environments/dev/main.tf

provider "aws" {
  region = var.aws_region
}

# 1. Instantiate Networking Module
module "networking" {
  source = "../../modules/networking"

  environment        = var.environment
  vpc_cidr           = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
}

# 2. Instantiate EKS Module
module "eks" {
  source = "../../modules/eks"

  environment        = var.environment
  private_subnet_ids = module.networking.private_subnet_ids

  # Cost-saving dev configurations
  node_instance_types = ["t3.medium"]
  node_desired_size   = 1
  node_min_size       = 1
  node_max_size       = 2
}