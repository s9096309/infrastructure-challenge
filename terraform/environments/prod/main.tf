# terraform/environments/prod/main.tf

provider "aws" {
  region = var.aws_region
}

# 1. Instantiate Networking Module (High Availability Setup)
module "networking" {
  source = "../../modules/networking"

  environment = var.environment
  vpc_cidr    = "10.1.0.0/16" # Different CIDR from dev to prevent routing overlaps

  # Spanning 3 Availability Zones for Production HA
  public_subnets     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnets    = ["10.1.10.0/24", "10.1.20.0/24", "10.1.30.0/24"]
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
}

# 2. Instantiate EKS Module (Production Compute)
module "eks" {
  source = "../../modules/eks"

  environment        = var.environment
  private_subnet_ids = module.networking.private_subnet_ids
  endpoint_public_access = var.endpoint_public_access

  # Production-grade compute and scaling
  node_instance_types = ["t3.large"]
  node_desired_size   = 3 # At least one node per AZ
  node_min_size       = 3
  node_max_size       = 6 # Room to scale during traffic spikes
}