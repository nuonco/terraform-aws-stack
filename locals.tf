locals {
  prefix = var.nuon_install_id
  region = var.aws_region

  # Resolved inline policy documents — full JSON document takes precedence over
  # the permissions shorthand. Empty string means no inline policy on this role.
  provision_inline_policy = (
    var.provision_inline_policy_document != "" ? var.provision_inline_policy_document :
    length(var.provision_permissions) > 0 ? jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = var.provision_permissions
        Resource = "*"
      }]
    }) : ""
  )
  maintenance_inline_policy = (
    var.maintenance_inline_policy_document != "" ? var.maintenance_inline_policy_document :
    length(var.maintenance_permissions) > 0 ? jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = var.maintenance_permissions
        Resource = "*"
      }]
    }) : ""
  )
  deprovision_inline_policy = (
    var.deprovision_inline_policy_document != "" ? var.deprovision_inline_policy_document :
    length(var.deprovision_permissions) > 0 ? jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = var.deprovision_permissions
        Resource = "*"
      }]
    }) : ""
  )

  has_provision   = local.provision_inline_policy != "" || length(var.provision_managed_policy_arns) > 0
  has_maintenance = local.maintenance_inline_policy != "" || length(var.maintenance_managed_policy_arns) > 0
  has_deprovision = local.deprovision_inline_policy != "" || length(var.deprovision_managed_policy_arns) > 0

  enabled_break_glass_roles = { for k, v in var.break_glass_roles : k => v if v.enabled }
  enabled_custom_roles      = { for k, v in var.custom_roles : k => v if v.enabled }

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

  tags = {
    "install.nuon.co/id" = var.nuon_install_id
    "nuon_install_id"    = var.nuon_install_id
  }
}
