terraform {
  backend "s3" {
    bucket         = "opsfleet-terraformstate"
    region         = "eu-west-1"
    acl            = "bucket-owner-full-control"
    dynamodb_table = "opsfleet-terraform-lock-table"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/TerraformRole"
  }
}
