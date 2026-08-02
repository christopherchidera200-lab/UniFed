variable "project" { type = string }
variable "environment" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "function_name" { type = string }
variable "api_name" { type = string }
variable "alarm_email" {
  description = "Address subscribed to the alarm topic. Empty disables notifications."
  type        = string
  default     = ""
}
variable "error_threshold" {
  type    = number
  default = 5
}
