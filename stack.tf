##
## Nuon control-plane configuration.
##
## Runner details, IAM permissions, roles, install inputs, and secret metadata
## are read from the Nuon API via the stack_config data source, keyed by
## install_id. This module has no tfvars-driven path — the control plane is
## the single source of truth.
##
## The read is authenticated: configure the stack provider with an api_token,
## or with org_id to exchange an ambient OIDC token in CI. The phone-home URL
## comes back in the response, so no per-stack-version secret is ever passed in
## as a variable.
##
## Non-secret values are read by indexing data.stack_config.this DIRECTLY —
## never via one()/try() over the whole object. Routing the object through a
## function collapses the sensitivity mark from the `secrets` attribute onto
## every sibling value, which would make unrelated outputs sensitive.
##

data "stack_config" "this" {
  install_id = var.install_id
}

locals {
  # identifiers
  nuon_install_id = data.stack_config.this.install_id
  nuon_org_id     = data.stack_config.this.org_id
  nuon_app_id     = data.stack_config.this.app_id

  # runner
  runner_id      = data.stack_config.this.runner_id
  runner_api_url = data.stack_config.this.runner_api_url
  phone_home_url = data.stack_config.this.phone_home_url

  region = data.stack_config.this.aws.region

  # Caller override wins; then the Nuon app runner config; then the platform
  # default, which also covers a ctl-api that does not yet serve the field.
  runner_machine_type = (
    var.runner_instance_type != "" ? var.runner_instance_type :
    data.stack_config.this.aws.runner_machine_type != "" ? data.stack_config.this.aws.runner_machine_type :
    "t3a.medium"
  )

  # control-plane accounts allowed to assume the operation roles
  nuon_support_iam_role_arns = data.stack_config.this.aws.nuon_support_iam_role_arns

  # operation-role permissions
  provision_permissions              = data.stack_config.this.aws.provision_permissions
  provision_inline_policy_document   = data.stack_config.this.aws.provision_inline_policy_document
  provision_managed_policy_arns      = data.stack_config.this.aws.provision_managed_policy_arns
  maintenance_permissions            = data.stack_config.this.aws.maintenance_permissions
  maintenance_inline_policy_document = data.stack_config.this.aws.maintenance_inline_policy_document
  maintenance_managed_policy_arns    = data.stack_config.this.aws.maintenance_managed_policy_arns
  deprovision_permissions            = data.stack_config.this.aws.deprovision_permissions
  deprovision_inline_policy_document = data.stack_config.this.aws.deprovision_inline_policy_document
  deprovision_managed_policy_arns    = data.stack_config.this.aws.deprovision_managed_policy_arns

  # Roles as the control plane serves them, with var.roles layered on top:
  # a value set there wins over the control plane's enabled flag in both
  # directions, so a caller can turn a role off or switch one on. If the same
  # name appears in both maps, the override applies to both. Unknown keys are
  # rejected at plan time by the precondition on stack_phone_home.this.
  #
  # Served role names double as the physical IAM role names, so vendors
  # template the install ID into them (see iam.tf). Callers may key var.roles
  # by the full name or by the short name with the leading "<install-id>-"
  # trimmed; the full name wins if both are set.
  role_name_prefix = "${var.install_id}-"
  break_glass_roles = {
    for k, v in data.stack_config.this.aws.break_glass_roles :
    k => merge(v, { enabled = lookup(var.roles, k, lookup(var.roles, trimprefix(k, local.role_name_prefix), v.enabled)) })
  }
  custom_roles = {
    for k, v in data.stack_config.this.aws.custom_roles :
    k => merge(v, { enabled = lookup(var.roles, k, lookup(var.roles, trimprefix(k, local.role_name_prefix), v.enabled)) })
  }

  # Reserved operation-role keys plus every served role name, in both full and
  # prefix-trimmed forms.
  known_role_keys = setunion(
    toset(["provision", "maintenance", "deprovision"]),
    keys(data.stack_config.this.aws.break_glass_roles),
    keys(data.stack_config.this.aws.custom_roles),
    toset([for k in keys(data.stack_config.this.aws.break_glass_roles) : trimprefix(k, local.role_name_prefix)]),
    toset([for k in keys(data.stack_config.this.aws.custom_roles) : trimprefix(k, local.role_name_prefix)]),
  )
  unknown_role_keys = setsubtract(keys(var.roles), local.known_role_keys)

  # What the precondition's error message displays: each role once, by its
  # short name, plus the reserved operation keys. known_role_keys (both forms)
  # remains the allowlist.
  display_role_keys = setunion(
    toset(["provision", "maintenance", "deprovision"]),
    toset([for k in keys(data.stack_config.this.aws.break_glass_roles) : trimprefix(k, local.role_name_prefix)]),
    toset([for k in keys(data.stack_config.this.aws.custom_roles) : trimprefix(k, local.role_name_prefix)]),
  )

  # inputs and secrets
  auto_generate_secrets = data.stack_config.this.auto_generate_secrets

  # The control plane serves the current value of every customer-facing input;
  # var.inputs is the caller's override and wins. The merged map is what the
  # stack applies with, and phone home reports it back so it becomes the
  # install's current inputs. Unknown keys are rejected at plan time by the
  # precondition on stack_phone_home.this.
  install_inputs = merge(
    data.stack_config.this.install_inputs,
    var.inputs,
  )

  unknown_input_keys = setsubtract(keys(var.inputs), keys(data.stack_config.this.install_inputs))

  # Secret values supplied via var.secrets win over the data source. The marks
  # that try() collapses here are all genuinely sensitive, so the collapse is
  # correct in this block specifically.
  secret_names = toset(concat(
    keys(nonsensitive(data.stack_config.this.secrets)),
    keys(nonsensitive(var.secrets)),
  ))
  secrets = {
    for k in local.secret_names : k => {
      description = coalesce(try(var.secrets[k].description, null), try(data.stack_config.this.secrets[k].description, null), "")
      required    = try(var.secrets[k].required, null) != null ? var.secrets[k].required : try(data.stack_config.this.secrets[k].required, false)
      value       = try(var.secrets[k].value, "") != "" ? var.secrets[k].value : try(data.stack_config.this.secrets[k].value, "")
    }
  }
}
