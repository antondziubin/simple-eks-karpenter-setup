tags = {
  "Environment" = "dev"
  "Project"     = "opsfleet"
  "Application" = "eks"
  "Terraform"   = "true"
}

account_id       = ""
main_project_tag = "opsfleet-eks"

eks_cluster_version            = "1.31"
cluster_endpoint_public_access = false
eks_network_policy_enable      = "true"
eks_network_policy_mode        = "standard" # 'strict'

vpc_project_tag = "opsfleet-vpc"

# EKS Access Entries
access_entries = {
  Terraform-Role = {
    principal_arn = "arn:aws:iam::123456789012:role/TerraformRole"
    policy_associations = {
      single = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type = "cluster"
        }
      }
    }
  }
}
