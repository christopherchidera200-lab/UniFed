output "api_endpoint" {
  value = aws_apigatewayv2_api.main.api_endpoint
}

output "function_name" {
  value = aws_lambda_function.api.function_name
}

output "function_arn" {
  value = aws_lambda_function.api.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.lambda.name
}
