# =============================================================================
# UniFed Nigeria - ADUN Reference Node - AWS Foundation
# Modular, portable infrastructure-as-code.
# Provides: VPC, EKS (Kubernetes), RDS PostgreSQL, ElastiCache (Redis),
#           OpenSearch, S3 (media), KMS, and base IAM.
# =============================================================================

# ---------------- Networking: VPC ----------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  name = "unifed-${var.node_slug}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = [for k, v in ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"] : v]
  public_subnets  = [for k, v in ["10.20.101.0/24", "10.20.102.0/24", "10.20.103.0/24"] : v]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
}

# ---------------- KMS for data at rest ----------------
resource "aws_kms_key" "unifed" {
  description             = "UniFed ${var.node_slug} envelope encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = { Name = "unifed-${var.node_slug}-kms" }
}

# ---------------- RDS PostgreSQL (academic + identity data) ----------------
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.5"

  identifier        = "unifed-${var.node_slug}-pg"
  engine            = "postgres"
  engine_version    = "16.4"
  instance_class    = var.db_instance_class
  allocated_storage = 100
  storage_encrypted = true
  kms_key_id        = aws_kms_key.unifed.arn

  db_name  = "unifed"
  username = "unifed"
  port     = 5432

  # Secrets managed via AWS Secrets Manager; password injected at runtime
  manage_master_user_password = true
  storage_type                = "gp3"

  vpc_security_group_ids = [module.sg_rds.security_group_id]
  subnet_ids             = module.vpc.private_subnets

  backup_retention_period = 14
  deletion_protection     = true
  multi_az                = true

  depends_on = [module.vpc]
}

# ---------------- ElastiCache Redis (sessions + cache) ----------------
module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.5"

  cluster_id                 = "unifed-${var.node_slug}-redis"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = "cache.r6g.large"
  num_cache_clusters         = 2
  subnet_ids                 = module.vpc.private_subnets
  security_group_ids         = [module.sg_redis.security_group_id]
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
}

# ---------------- S3 (media: avatars, docs, stream recordings) ----------------
resource "aws_s3_bucket" "media" {
  bucket = "unifed-${var.node_slug}-media"
  tags   = { Name = "unifed-${var.node_slug}-media" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.unifed.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------- EKS (Kubernetes) ----------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.15"

  cluster_name    = "unifed-${var.node_slug}"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true
  enable_irsa                    = true

  eks_managed_node_groups = {
    general = {
      instance_types = var.eks_node_instance_types
      min_size       = 2
      max_size       = 6
      desired_size   = 3
      labels         = { workload = "general" }
    }
  }

  depends_on = [module.vpc]
}

# ---------------- Security Groups ----------------
module "sg_rds" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"
  name    = "unifed-${var.node_slug}-rds"
  vpc_id  = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    { from_port = 5432, to_port = 5432, protocol = "tcp", cidr_blocks = var.vpc_cidr }
  ]
}

module "sg_redis" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"
  name    = "unifed-${var.node_slug}-redis"
  vpc_id  = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    { from_port = 6379, to_port = 6379, protocol = "tcp", cidr_blocks = var.vpc_cidr }
  ]
}

