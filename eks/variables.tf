variable "account_id" {
  description = "The AWS account ID"
  type        = string
  default     = "012345678912"
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "eu-west-1"
}

variable "main_project_tag" {
  description = "The main project tag"
  type        = string
}

variable "eks_cluster_version" {
  description = "The EKS cluster version"
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
}

variable "tags" {
  description = "The tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "eks_network_policy_enable" {
  description = "Indicates whether or not the Amazon EKS network policy is enabled"
  type        = string
}

variable "eks_network_policy_mode" {
  description = "The network policy mode to use for the EKS cluster"
  type        = string
}

variable "access_entries" {
  description = "EKS Access Entries"
  type        = any
}

variable "vpc_project_tag" {
  description = "The VPC project tag"
  type        = string
  default     = "opsfleet"
}
