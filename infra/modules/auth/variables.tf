variable "project" { type = string }
variable "environment" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "callback_urls" {
  description = "Allowed OAuth callback URLs for the web client"
  type        = list(string)
  default     = ["http://localhost:3000/api/auth/callback/cognito"]
}
variable "logout_urls" {
  type    = list(string)
  default = ["http://localhost:3000"]
}
