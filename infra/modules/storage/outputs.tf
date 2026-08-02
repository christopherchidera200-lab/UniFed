output "table_name" {
  value = aws_dynamodb_table.main.name
}

output "table_arn" {
  value = aws_dynamodb_table.main.arn
}

output "table_gsi_arns" {
  value = ["${aws_dynamodb_table.main.arn}/index/*"]
}

output "reports_bucket" {
  value = aws_s3_bucket.reports.id
}

output "reports_bucket_arn" {
  value = aws_s3_bucket.reports.arn
}

output "kms_key_arn" {
  value = aws_kms_key.main.arn
}
