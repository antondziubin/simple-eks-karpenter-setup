##############################################
#### VPC CNI
##############################################
data "aws_iam_policy" "AmazonEKS_CNI_Policy" {
  name = "AmazonEKS_CNI_Policy"
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = false
  vpc_cni_enable_ipv6   = false

  role_policy_arns = {
    policy = data.aws_iam_policy.AmazonEKS_CNI_Policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = var.tags
}

##############################################
#### EBS CSI Driver
##############################################
data "aws_iam_policy" "AmazonEBSCSIDriverPolicy" {
  name = "AmazonEBSCSIDriverPolicy"
}

module "aws_ebs_csi_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${var.main_project_tag}-${var.environment}-aws-ebs-csi-driver"

  role_policy_arns = {
    policy = data.aws_iam_policy.AmazonEBSCSIDriverPolicy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}
