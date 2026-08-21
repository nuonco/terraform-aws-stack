##
## Module inputs.
##
## Almost everything this module needs is read from the Nuon control plane via
## the stack_config data source (see stack.tf). Only the values below cannot
## come from the API, or are deliberate caller-side overrides.
##

variable "phone_home_id" {
  type        = string
  description = "Per-stack-version identifier issued by the Nuon control plane. Used by the stack_config data source to fetch this install's configuration."

  validation {
    condition     = var.phone_home_id != ""
    error_message = "phone_home_id must be set; it is the key used to fetch this install's configuration."
  }
}

variable "runner_enabled" {
  type        = bool
  default     = true
  description = "Whether to provision the runner module (ASG, launch template, log group). Set to false to skip the runner and only create networking, IAM, and secrets."
}

variable "runner_instance_type" {
  type        = string
  default     = ""
  description = "Optional override for the runner's EC2 instance type. When empty, the type is read from the Nuon app runner config, falling back to t3a.medium."
}

variable "secrets" {
  type = map(object({
    description = optional(string)
    required    = optional(bool)
    value       = optional(string)
  }))
  default     = {}
  sensitive   = true
  description = "Secret overrides keyed by name, layered over the stack_config data source. Any field set here wins. Use this to supply secret values the control plane does not hold."
}
