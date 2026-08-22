variable "install_id" {
  type        = string
  description = "Nuon install ID. Identifies which install to configure; not a credential."
}

variable "api_token" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Nuon API token, issued alongside the install. Leave empty to fall back to NUON_API_TOKEN, or to OIDC when org_id is set."
}

variable "org_id" {
  type        = string
  default     = ""
  description = "Nuon organization ID. Required only when authenticating via OIDC instead of a token."
}

variable "aws_region" {
  type        = string
  description = "Region to configure the aws provider with. Must match the region Nuon has recorded for this install."
}

variable "api_url" {
  type        = string
  default     = "https://runner.nuon.co"
  description = "Base URL of the Nuon runner API, up to but excluding /v1."
}
