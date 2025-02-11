module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.23.0"

  cluster_name    = "${var.main_project_tag}-${var.environment}"
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access = var.cluster_endpoint_public_access

  cluster_addons = {
    coredns = {
      addon_version = "v1.11.4-eksbuild.2"
      configuration_values = jsonencode({
        computeType  = "Fargate"
        replicaCount = 4
        resources = {
          requests = {
            cpu    = "0.35"
            memory = "512M"
          }
          limits = {
            cpu    = "0.5"
            memory = "512M"
          }
        }
        corefile = <<-EOT
        .:53 {
            errors
            health {
                lameduck 30s
              }
            ready
            kubernetes cluster.local in-addr.arpa ip6.arpa {
              pods insecure
              fallthrough in-addr.arpa ip6.arpa
            }
            prometheus :9153
            forward . /etc/resolv.conf
            cache 30
            loop
            reload
            loadbalance
        }
EOT
      })
      preserve = true
      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    kube-proxy = {
      addon_version = "v1.31.3-eksbuild.2"
    }
    vpc-cni = {
      addon_version            = "v1.19.2-eksbuild.1"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        enableNetworkPolicy = var.eks_network_policy_enable
        env = {
          "NETWORK_POLICY_ENFORCING_MODE" = var.eks_network_policy_mode
        }
      })
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.38.1-eksbuild.2"
      service_account_role_arn = module.aws_ebs_csi_role.iam_role_arn
    }
  }

  access_entries = var.access_entries

  # External encryption key
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.kms.key_arn
  }

  enable_irsa              = true
  vpc_id                   = data.aws_vpc.vpc.id
  subnet_ids               = data.aws_subnets.private_subnets.ids
  control_plane_subnet_ids = data.aws_subnets.private_subnets.ids


  eks_managed_node_groups = {
    opsfleet-eks-bootstrap = {
      name            = "opsfleet-eks-bootstrap"
      use_name_prefix = true
      desired_size    = 1
      min_size        = 0
      max_size        = 1

      ami_type = "BOTTLEROCKET_ARM_64"

      instance_types = ["m6g.2xlarge"]
      capacity_type  = "ON_DEMAND"
      labels = {
        NodeGroupType = "Bootstrap"
        Environment   = var.environment
      }
      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      update_config = {
        max_unavailable_percentage = 100
      }
    }

  }

  fargate_profiles = [
    {
      name            = "opsfleet-eks-fargate"
      create_iam_role = false
      iam_role_arn    = aws_iam_role.eks_fargate_execution_role.arn
      selectors = [
        {
          namespace = "karpenter"
        },
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        }
      ]
    }
  ]

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  node_security_group_tags = merge(var.tags, {
    "karpenter.sh/discovery" = "${var.main_project_tag}-${var.environment}"
  })

  cluster_security_group_tags = merge(var.tags, {
    "karpenter.sh/discovery" = "${var.main_project_tag}-${var.environment}"
  })

  tags = var.tags
}

resource "aws_security_group_rule" "fargate_cluster_to_nodes_ingress" {
  security_group_id        = module.eks.cluster_primary_security_group_id
  type                     = "ingress"
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.eks.node_security_group_id
  from_port                = 0
}


resource "aws_security_group_rule" "fargate_nodes_to_cluster_ingress" {
  security_group_id        = module.eks.node_security_group_id
  type                     = "ingress"
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.eks.cluster_primary_security_group_id
  from_port                = 0
}
