variable "project" { type = string }
variable "environment" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

variable "table_name" { type = string }
variable "table_arn" { type = string }
variable "table_gsi_arns" { type = list(string) }
variable "reports_bucket" { type = string }
variable "reports_bucket_arn" { type = string }
variable "kms_key_arn" { type = string }

variable "cognito_user_pool_id" { type = string }
variable "cognito_client_id" { type = string }
variable "cognito_user_pool_arn" { type = string }

variable "lambda_package" {
  description = "Path to the built Lambda deployment zip"
  type        = string
}

variable "memory_mb" {
  type    = number
  default = 512
}

variable "timeout_seconds" {
  description = "Must exceed the orchestrator budget but stay under API Gateway's 29s limit"
  type        = number
  default     = 29
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "cors_origins" {
  type    = list(string)
  default = ["http://localhost:3000"]
}

variable "throttle_burst" {
  type    = number
  default = 20
}

variable "throttle_rate" {
  type    = number
  default = 10
}
