variable "aws_region" {
  description = "AWS region for EKS and supporting resources"
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "case-devops-eks"
}

variable "environment" {
  description = "Environment tag (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS node group (birden fazla tip kapasite durumu)"
  type        = list(string)
  default     = ["t3.small", "t3.medium", "t2.small", "t2.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}
