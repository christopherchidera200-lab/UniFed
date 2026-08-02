locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Workload    = "osint-saas"
  }
}

module "storage" {
  source = "../../modules/storage"

  project     = var.project
  environment = var.environment
  tags        = local.tags
}

module "auth" {
  source = "../../modules/auth"

  project     = var.project
  environment = var.environment
  tags        = local.tags

  callback_urls = ["${var.frontend_origin}/api/auth/callback/cognito"]
  logout_urls   = [var.frontend_origin]
}

module "api" {
  source = "../../modules/api"

  project     = var.project
  environment = var.environment
  tags        = local.tags

  table_name         = module.storage.table_name
  table_arn          = module.storage.table_arn
  table_gsi_arns     = module.storage.table_gsi_arns
  reports_bucket     = module.storage.reports_bucket
  reports_bucket_arn = module.storage.reports_bucket_arn
  kms_key_arn        = module.storage.kms_key_arn

  cognito_user_pool_id  = module.auth.user_pool_id
  cognito_user_pool_arn = module.auth.user_pool_arn
  cognito_client_id     = module.auth.client_id

  lambda_package = var.lambda_package
  cors_origins   = [var.frontend_origin]
}

module "observability" {
  source = "../../modules/observability"

  project     = var.project
  environment = var.environment
  tags        = local.tags

  function_name = module.api.function_name
  api_name      = module.api.api_endpoint
  alarm_email   = var.alarm_email
}
