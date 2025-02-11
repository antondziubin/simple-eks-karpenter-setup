data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_project_tag}-${var.environment}"]
  }
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*-private-*"]
  }
}

# EKS cluster
data "aws_eks_cluster" "opsfleet_eks" {
  name = "opsfleet-eks-${var.environment}"
}

# EKS node security group
data "aws_security_group" "eks_node_sg" {
  filter {
    name   = "group-name"
    values = ["opsfleet-eks-${var.environment}-node-*"]
  }
}

# To get arn of eks oidc provider
data "aws_iam_openid_connect_provider" "opsfleet_eks_oidc" {
  url = data.aws_eks_cluster.opsfleet_eks.identity[0].oidc[0].issuer
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}