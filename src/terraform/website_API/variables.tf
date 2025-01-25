variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_profile" {
  description = "SSO profile"
  type        = string
  sensitive   = true
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags for the project"
  type        = map(string)
}
