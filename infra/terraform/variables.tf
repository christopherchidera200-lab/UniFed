variable "aws_region" {
  description = "Primary AWS region for the reference node (Cape Town is closest to Nigeria)"
  type        = string
  default     = "af-south-1"
}

variable "stage" {
  description = "Deployment stage"
  type        = string
  default     = "prod"
}

variable "node_slug" {
  description = "University node slug, e.g. adun, unilag, unn"
  type        = string
  default     = "adun"
}

variable "vpc_cidr" {
  description = "CIDR block for the node VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "eks_node_instance_types" {
  description = "EKS managed node instance types"
  type        = list(string)
  default     = ["m6i.large", "m6i.xlarge"]
}

variable "domain" {
  description = "Base domain for this node, e.g. adun.unifed.ng"
  type        = string
  default     = "adun.unifed.ng"
}
