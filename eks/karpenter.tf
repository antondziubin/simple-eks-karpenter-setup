#######################################
## Karpenter
#######################################
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.26.0"

  cluster_name           = data.aws_eks_cluster.opsfleet_eks.name
  enable_irsa            = true
  irsa_oidc_provider_arn = data.aws_iam_openid_connect_provider.opsfleet_eks_oidc.arn

  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  tags = var.tags
}

resource "aws_iam_service_linked_role" "ec2_spot" {
  description      = "Default EC2 Spot Service Linked Role"
  aws_service_name = "spot.amazonaws.com"
}


resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "0.36.2"

  set {
    name  = "settings.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.iam_role_arn
  }

  set {
    name  = "settings.interruptionQueue"
    value = module.karpenter.queue_name
  }

  depends_on = [module.karpenter]
}

resource "kubectl_manifest" "karpenter_private_multiarch_node_pool" {
  yaml_body = file("kubectl/karpenter/karpenter-private-multiarch-nodePool.yaml")

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_private_multiarch_node_class" {
  yaml_body = templatefile("kubectl/karpenter/karpenter-private-multiarch-nodeClass.yaml", {
    CLUSTER_NAME        = module.eks.cluster_name
    KARPENTER_ROLE_NAME = module.karpenter.node_iam_role_name
  })

  depends_on = [
    helm_release.karpenter
  ]
}

