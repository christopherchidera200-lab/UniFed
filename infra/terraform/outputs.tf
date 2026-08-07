output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value     = module.rds.db_instance_endpoint
  sensitive = true
}

output "redis_endpoint" {
  value = module.elasticache.cache_cluster_address
}

output "opensearch_endpoint" {
  value = module.opensearch.domain_endpoint
}

output "media_bucket" {
  value = aws_s3_bucket.media.id
}

output "kms_key_arn" {
  value = aws_kms_key.unifed.arn
}
