#################################################################################
## Supporting resources
#################################################################################
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["eks/${var.main_project_tag}-${var.environment}"]
  description           = "${var.main_project_tag}-${var.environment} cluster encryption key"
  enable_default_policy = true
  key_owners            = ["arn:aws:iam::${var.account_id}:role/TerraformRole"]

  tags = var.tags
}
