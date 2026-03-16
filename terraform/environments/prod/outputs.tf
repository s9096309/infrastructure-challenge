# terraform/environments/prod/outputs.tf

output "cluster_name" {
  description = "The name of the provisioned EKS cluster"
  value       = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Run this command to configure your local kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}