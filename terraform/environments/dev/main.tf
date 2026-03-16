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

# 3. Configure Helm Provider
# Tell Helm how to securely authenticate with the new EKS cluster
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
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

  # Inject DEV-specific values file
  values = [
    file("../../../helm/pumpkin-app/values-dev.yaml")
  ]

  # Ensure cluster is fully ready before deploying
  depends_on = [module.eks]
}