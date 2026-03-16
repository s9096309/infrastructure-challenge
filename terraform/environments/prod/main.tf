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

  # Production-grade compute and scaling
  node_instance_types = ["t3.large"]
  node_desired_size   = 3 # At least one node per AZ
  node_min_size       = 3
  node_max_size       = 6 # Room to scale during traffic spikes
}

# 3. Configure Helm Provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

# 4. Deploy Workload via Helm
resource "helm_release" "pumpkin_app" {
  name             = "pumpkin-app"
  chart            = "../../../helm/pumpkin-app"
  namespace        = "application"
  create_namespace = true

  # Inject PROD-specific values file
  values = [
    file("../../../helm/pumpkin-app/values-prod.yaml")
  ]

  depends_on = [module.eks]
}