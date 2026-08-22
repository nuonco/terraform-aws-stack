# Complete example.
#
# Networking, IAM roles, secrets, and the runner. Note how little is passed in:
# IAM permissions, operation roles, install inputs, and the runner machine type
# all come from the Nuon control plane, keyed by install_id.

module "aws_stack" {
  source = "../../"

  install_id = var.install_id

  # Optional: override the machine type from the Nuon app runner config.
  runner_instance_type = "t3.large"

  # Secret values the control plane does not hold. Metadata (description,
  # required) still comes from the data source unless overridden here.
  secrets = {
    api_key = {
      value = var.api_key
    }
  }
}

variable "api_key" {
  type        = string
  sensitive   = true
  description = "Value for the api_key secret."
}
