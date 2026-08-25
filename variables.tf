##
## Module inputs.
##
## Almost everything this module needs is read from the Nuon control plane via
## the stack_config data source (see stack.tf). Only the values below cannot
## come from the API, or are deliberate caller-side overrides.
##

variable "install_id" {
  type        = string
  description = "Nuon install ID. Identifies which install's configuration to read; not a credential — the stack provider's api_token authorizes the read."

  validation {
    condition     = var.install_id != ""
    error_message = "install_id must be set; it identifies which install's configuration to fetch."
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

variable "inputs" {
  type        = map(string)
  default     = {}
  description = "Customer-facing install input values keyed by name. Layered over the values the Nuon control plane holds — any value set here wins — and reported back via phone home, where it becomes the install's current inputs. Keys must match inputs the app declares; unknown keys fail the plan, as does a required input that resolves to no value."
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

variable "roles" {
  type        = map(bool)
  default     = {}
  description = "Per-role enable/disable overrides. Break-glass and custom roles are keyed by role name — the full served name or the name without its leading <install-id>- prefix — and a value set here wins over the control plane's enabled flag. The reserved keys provision, maintenance, and deprovision disable an operation role; disabling one prevents Nuon from performing that operation on the install until it is re-enabled and applied. Unknown keys fail the plan."
}
