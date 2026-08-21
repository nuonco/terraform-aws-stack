# These values are supplied by Nuon in the generated tfvars file for an install.

variable "aws_region" {
  type        = string
  description = "AWS region to provision into. Must match the provider region."
}

variable "nuon_install_id" {
  type        = string
  description = "The Nuon install ID for this deployment."
}

variable "nuon_org_id" {
  type        = string
  description = "The Nuon organization ID."
}

variable "nuon_app_id" {
  type        = string
  description = "The Nuon application ID."
}

variable "runner_api_url" {
  type        = string
  description = "The URL of the Nuon runner API."
}

variable "runner_id" {
  type        = string
  description = "The Nuon runner ID."
}

variable "phone_home_url" {
  type        = string
  description = "The URL the module calls to report provisioning results back to Nuon."
}

variable "nuon_support_iam_role_arns" {
  type        = list(string)
  default     = []
  description = "Nuon control-plane IAM role ARNs permitted to assume the operation roles."
}
