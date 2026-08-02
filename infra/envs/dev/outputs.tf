output "api_endpoint" {
  description = "Base URL for the CloudIntel API"
  value       = module.api.api_endpoint
}

output "cognito_user_pool_id" {
  value = module.auth.user_pool_id
}

output "cognito_client_id" {
  value = module.auth.client_id
}

output "cognito_hosted_ui" {
  value = module.auth.hosted_ui_domain
}

output "table_name" {
  value = module.storage.table_name
}

output "reports_bucket" {
  value = module.storage.reports_bucket
}

output "dashboard" {
  value = module.observability.dashboard_name
}
