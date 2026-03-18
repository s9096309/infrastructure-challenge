# terraform/modules/eks/variables.tf

variable "environment" {
  description = "The environment name (e.g., dev, prod)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where nodes and control plane ENIs will be placed"
  type        = list(string)
}

variable "node_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "endpoint_public_access" {
  description = "Allow public access"
  type        = bool
  default     = true
}