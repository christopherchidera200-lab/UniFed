variable "project" {
  type    = string
  default = "cloudintel"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "lambda_package" {
  description = "Path to the built deployment zip (produced by scripts/build_lambda.sh)"
  type        = string
  default     = "../../../backend/dist/lambda.zip"
}

variable "alarm_email" {
  type    = string
  default = ""
}

variable "frontend_origin" {
  type    = string
  default = "http://localhost:3000"
}
