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

resource "aws_secretsmanager_secret" "customer" {
  for_each = toset(nonsensitive(keys(var.secrets)))
  name     = "${local.prefix}-${each.key}"
  tags     = local.tags
}

resource "aws_secretsmanager_secret_version" "customer" {
  for_each      = toset(nonsensitive(keys(var.secrets)))
  secret_id     = aws_secretsmanager_secret.customer[each.key].id
  secret_string = var.secrets[each.key].value

  lifecycle {
    ignore_changes = [secret_string]
  }
}
