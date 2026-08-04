###############################################################################
# Auto-generated secrets
###############################################################################

resource "random_password" "auto_generate" {
  for_each = toset(var.auto_generate_secrets)
  length   = 63
  special  = false

  keepers = {
    secret_name = each.key
    install_id  = var.nuon_install_id
  }
}

resource "aws_secretsmanager_secret" "auto_generate" {
  for_each = toset(var.auto_generate_secrets)
  name     = "${local.prefix}-${each.key}"
  tags     = local.tags
}

resource "aws_secretsmanager_secret_version" "auto_generate" {
  for_each      = toset(var.auto_generate_secrets)
  secret_id     = aws_secretsmanager_secret.auto_generate[each.key].id
  secret_string = random_password.auto_generate[each.key].result

  lifecycle {
    ignore_changes = [secret_string]
  }
}

###############################################################################
# Customer-provided secrets
###############################################################################

# Skip secrets with empty values — AWS rejects empty payloads, and an optional
# secret left unset shouldn't be created at all.
locals {
  customer_secret_keys = toset(nonsensitive([for k, v in var.secrets : k if v.value != ""]))
}

resource "aws_secretsmanager_secret" "customer" {
  for_each = local.customer_secret_keys
  name     = "${local.prefix}-${each.key}"
  tags     = local.tags
}

resource "aws_secretsmanager_secret_version" "customer" {
  for_each      = local.customer_secret_keys
  secret_id     = aws_secretsmanager_secret.customer[each.key].id
  secret_string = var.secrets[each.key].value

  lifecycle {
    ignore_changes = [secret_string]
  }
}

###############################################################################
# Telemetry export configuration
###############################################################################

resource "aws_secretsmanager_secret" "telemetry_export_config" {
  count                   = nonsensitive(var.telemetry_export_config != "") ? 1 : 0
  name                    = "nuon/${var.nuon_install_id}/telemetry-export-config"
  recovery_window_in_days = 0
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "telemetry_export_config" {
  count         = nonsensitive(var.telemetry_export_config != "") ? 1 : 0
  secret_id     = aws_secretsmanager_secret.telemetry_export_config[0].id
  secret_string = var.telemetry_export_config
}
