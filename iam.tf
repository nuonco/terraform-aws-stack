###############################################################################
# Runner instance role + instance profile
###############################################################################

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner" {
  name               = "${local.prefix}-runner"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.tags
}

resource "aws_iam_instance_profile" "runner" {
  name = "${local.prefix}-runner"
  role = aws_iam_role.runner.name
  tags = local.tags
}

# The runner needs to assume the operation roles (provision/maintenance/deprovision/etc)
# and read its own secrets. Apps configure the policies attached to each role.
data "aws_iam_policy_document" "runner_inline" {
  statement {
    sid     = "AssumeOperationRoles"
    actions = ["sts:AssumeRole"]
    resources = compact([
      local.has_provision ? aws_iam_role.provision[0].arn : "",
      local.has_maintenance ? aws_iam_role.maintenance[0].arn : "",
      local.has_deprovision ? aws_iam_role.deprovision[0].arn : "",
    ])
  }

  dynamic "statement" {
    for_each = length(local.enabled_break_glass_roles) > 0 ? [1] : []
    content {
      sid       = "AssumeBreakGlassRoles"
      actions   = ["sts:AssumeRole"]
      resources = [for k, _ in local.enabled_break_glass_roles : aws_iam_role.break_glass[k].arn]
    }
  }

  dynamic "statement" {
    for_each = length(local.enabled_custom_roles) > 0 ? [1] : []
    content {
      sid       = "AssumeCustomRoles"
      actions   = ["sts:AssumeRole"]
      resources = [for k, _ in local.enabled_custom_roles : aws_iam_role.custom[k].arn]
    }
  }

  statement {
    sid = "ReadOwnSecrets"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = ["arn:aws:secretsmanager:*:*:secret:${local.prefix}-*"]
  }

  statement {
    sid = "ReadTelemetryExportConfig"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:${local.region}:${data.aws_caller_identity.current.account_id}:secret:nuon/${local.prefix}/telemetry-export-config-*",
    ]
  }

  statement {
    sid = "RunnerCloudWatchLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/nuon/${local.prefix}/*",
      "arn:aws:logs:*:*:log-group:runner-*",
      "arn:aws:logs:*:*:log-group:runner-*:*",
    ]
  }

  # init-mng-v2.sh reads instance tags (nuon_runner_id, nuon_runner_api_url) via DescribeTags.
  statement {
    sid       = "RunnerDescribeTags"
    actions   = ["ec2:DescribeTags"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "runner_inline" {
  name   = "${local.prefix}-runner-inline"
  role   = aws_iam_role.runner.id
  policy = data.aws_iam_policy_document.runner_inline.json
}

###############################################################################
# Trust policy: control-plane accounts assume the operation roles
###############################################################################

data "aws_iam_policy_document" "control_plane_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = length(local.nuon_support_iam_role_arns) > 0 ? local.nuon_support_iam_role_arns : [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.runner.arn]
    }
  }
}

data "aws_caller_identity" "current" {}

###############################################################################
# Provision role
###############################################################################

resource "aws_iam_role" "provision" {
  count              = local.has_provision ? 1 : 0
  name               = "${local.prefix}-provision"
  assume_role_policy = data.aws_iam_policy_document.control_plane_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "provision_inline" {
  count  = local.has_provision && local.provision_inline_policy != "" ? 1 : 0
  name   = "${local.prefix}-provision-inline"
  role   = aws_iam_role.provision[0].id
  policy = local.provision_inline_policy
}

resource "aws_iam_role_policy_attachment" "provision_managed" {
  for_each   = local.has_provision ? toset(local.provision_managed_policy_arns) : toset([])
  role       = aws_iam_role.provision[0].name
  policy_arn = each.value
}

###############################################################################
# Maintenance role
###############################################################################

resource "aws_iam_role" "maintenance" {
  count              = local.has_maintenance ? 1 : 0
  name               = "${local.prefix}-maintenance"
  assume_role_policy = data.aws_iam_policy_document.control_plane_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "maintenance_inline" {
  count  = local.has_maintenance && local.maintenance_inline_policy != "" ? 1 : 0
  name   = "${local.prefix}-maintenance-inline"
  role   = aws_iam_role.maintenance[0].id
  policy = local.maintenance_inline_policy
}

resource "aws_iam_role_policy_attachment" "maintenance_managed" {
  for_each   = local.has_maintenance ? toset(local.maintenance_managed_policy_arns) : toset([])
  role       = aws_iam_role.maintenance[0].name
  policy_arn = each.value
}

###############################################################################
# Deprovision role
###############################################################################

resource "aws_iam_role" "deprovision" {
  count              = local.has_deprovision ? 1 : 0
  name               = "${local.prefix}-deprovision"
  assume_role_policy = data.aws_iam_policy_document.control_plane_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "deprovision_inline" {
  count  = local.has_deprovision && local.deprovision_inline_policy != "" ? 1 : 0
  name   = "${local.prefix}-deprovision-inline"
  role   = aws_iam_role.deprovision[0].id
  policy = local.deprovision_inline_policy
}

resource "aws_iam_role_policy_attachment" "deprovision_managed" {
  for_each   = local.has_deprovision ? toset(local.deprovision_managed_policy_arns) : toset([])
  role       = aws_iam_role.deprovision[0].name
  policy_arn = each.value
}

###############################################################################
# Break-glass roles (dynamic, one per enabled role)
###############################################################################

# Role names come from the ctl-api renderer with install-id templating already
# applied by the vendor's stack.toml — match CFN's contract (`RoleName: role.Name`)
# and use each.key verbatim. Rewrapping with `${local.prefix}-bg-` here would
# double-prefix and overflow IAM's 64-char role-name limit.
resource "aws_iam_role" "break_glass" {
  for_each           = local.enabled_break_glass_roles
  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.control_plane_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "break_glass_inline" {
  for_each = { for k, v in local.enabled_break_glass_roles : k => v if local.break_glass_inline_policies[k] != "" }
  name     = "${each.key}-inline"
  role     = aws_iam_role.break_glass[each.key].id
  policy   = local.break_glass_inline_policies[each.key]
}

resource "aws_iam_role_policy_attachment" "break_glass_managed" {
  for_each = merge([
    for k, v in local.enabled_break_glass_roles : {
      for arn in v.managed_policy_arns : "${k}__${arn}" => { role = k, arn = arn }
    }
  ]...)
  role       = aws_iam_role.break_glass[each.value.role].name
  policy_arn = each.value.arn
}

###############################################################################
# Custom roles (dynamic, one per enabled role)
###############################################################################

resource "aws_iam_role" "custom" {
  for_each           = local.enabled_custom_roles
  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.control_plane_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "custom_inline" {
  for_each = { for k, v in local.enabled_custom_roles : k => v if local.custom_inline_policies[k] != "" }
  name     = "${each.key}-inline"
  role     = aws_iam_role.custom[each.key].id
  policy   = local.custom_inline_policies[each.key]
}

resource "aws_iam_role_policy_attachment" "custom_managed" {
  for_each = merge([
    for k, v in local.enabled_custom_roles : {
      for arn in v.managed_policy_arns : "${k}__${arn}" => { role = k, arn = arn }
    }
  ]...)
  role       = aws_iam_role.custom[each.value.role].name
  policy_arn = each.value.arn
}
