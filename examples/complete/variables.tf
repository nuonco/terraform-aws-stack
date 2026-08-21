variable "phone_home_id" {
  type        = string
  description = "Per-stack-version identifier issued by the Nuon control plane."
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
