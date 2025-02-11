# EKS OIDC Provider ARN
output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

# EKS Cluster Name
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

# EKS Cluster Certificate Authority Data
output "eks_cluster_certificate_authority_data" {
  value     = module.eks.cluster_certificate_authority_data
  sensitive = true
}

# EKS Cluster Endpoint
output "eks_cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

# EKS Cluster Security Group ID
output "eks_node_security_group_id" {
  value = module.eks.node_security_group_id
}
