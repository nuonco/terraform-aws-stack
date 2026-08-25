locals {
  prefix = local.nuon_install_id

  # Resolved inline policy documents — full JSON document takes precedence over
  # the permissions shorthand. Empty string means no inline policy on this role.
  provision_inline_policy = (
    local.provision_inline_policy_document != "" ? local.provision_inline_policy_document :
    length(local.provision_permissions) > 0 ? jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = local.provision_permissions
        Resource = "*"
      }]
    }) : ""
  )
  maintenance_inline_policy = (
    local.maintenance_inline_policy_document != "" ? local.maintenance_inline_policy_document :
    length(local.maintenance_permissions) > 0 ? jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = local.maintenance_permissions
        Resource = "*"
      }]
    }) : ""
  )
  deprovision_inline_policy = (
    local.deprovision_inline_policy_document != "" ? local.deprovision_inline_policy_document :
    length(local.deprovision_permissions) > 0 ? jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = local.deprovision_permissions
        Resource = "*"
      }]
    }) : ""
  )

  # The reserved var.roles keys "provision"/"maintenance"/"deprovision" let the
  # caller disable an operation role. Effectively disable-only: enabling a role
  # the app config grants no policies to would create an empty role, so the
  # policy check still applies.
  has_provision   = lookup(var.roles, "provision", true) && (local.provision_inline_policy != "" || length(local.provision_managed_policy_arns) > 0)
  has_maintenance = lookup(var.roles, "maintenance", true) && (local.maintenance_inline_policy != "" || length(local.maintenance_managed_policy_arns) > 0)
  has_deprovision = lookup(var.roles, "deprovision", true) && (local.deprovision_inline_policy != "" || length(local.deprovision_managed_policy_arns) > 0)

  enabled_break_glass_roles = { for k, v in local.break_glass_roles : k => v if v.enabled }
  enabled_custom_roles      = { for k, v in local.custom_roles : k => v if v.enabled }

  break_glass_inline_policies = {
    for k, v in local.enabled_break_glass_roles : k => (
      v.inline_policy_document != "" ? v.inline_policy_document :
      length(v.permissions) > 0 ? jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = v.permissions
          Resource = "*"
        }]
      }) : ""
    )
  }
  custom_inline_policies = {
    for k, v in local.enabled_custom_roles : k => (
      v.inline_policy_document != "" ? v.inline_policy_document :
      length(v.permissions) > 0 ? jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = v.permissions
          Resource = "*"
        }]
      }) : ""
    )
  }

  # These will be empty strings when the runner is disabled.
  runner_asg_name       = var.runner_enabled ? module.runner[0].asg_name : ""
  runner_log_group_name = var.runner_enabled ? module.runner[0].log_group_name : ""

  tags = {
    "install.nuon.co/id" = local.nuon_install_id
    "nuon_install_id"    = local.nuon_install_id
  }
}
