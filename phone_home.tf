locals {
  break_glass_role_arns = { for k, v in aws_iam_role.break_glass : k => v.arn }
  custom_role_arns      = { for k, v in aws_iam_role.custom : k => v.arn }

  # Secret ARNs are flattened into the top-level payload as `<name>_arn`,
  # matching what the CloudFormation phone-home Lambda emits so app templates
  # referencing `nuon.install_stack.outputs.<secret_name>_arn` resolve
  # identically across both install paths.
  auto_generate_secret_arns = {
    for k, v in aws_secretsmanager_secret.auto_generate :
    "${k}_arn" => v.arn
  }
  customer_secret_arns = {
    for k, v in aws_secretsmanager_secret.customer :
    "${k}_arn" => v.arn
  }
  all_secret_arns = merge(local.auto_generate_secret_arns, local.customer_secret_arns)

  # Key names below mirror the CloudFormation phone-home Lambda payload
  # so app templates referencing `nuon.install_stack.outputs.*` resolve
  # identically whether the customer applied via CFN or Terraform.
  phone_home_payload = merge({
    account_id = data.aws_caller_identity.current.account_id
    region     = local.region
    vpc_id     = module.vpc.vpc_id
    # Subnet lists are emitted as comma-joined strings to match the CFN
    # phone-home Lambda payload (CFN stack outputs are strings, joined with
    # `Fn::Join`). ctl-api's `updateinstallstackoutputs` decoder uses
    # `StringToSliceHookFunc(",")` to split them back into []string, so the
    # downstream stack outputs end up as proper lists either way. Sending an
    # actual JSON list here would land in postgres HSTORE as the string
    # "[subnet-x subnet-y]" (space-separated) and decode to an empty list.
    runner_subnet            = module.vpc.runner_subnet_id
    public_subnets           = join(",", module.vpc.public_subnet_ids)
    private_subnets          = join(",", module.vpc.private_subnet_ids)
    runner_security_group_id = module.vpc.runner_security_group_id
    runner_iam_role_arn      = aws_iam_role.runner.arn
    runner_instance_profile  = aws_iam_instance_profile.runner.arn
    runner_asg_name          = local.runner_asg_name
    runner_log_group_name    = local.runner_log_group_name
    provision_iam_role_arn   = local.has_provision ? aws_iam_role.provision[0].arn : ""
    maintenance_iam_role_arn = local.has_maintenance ? aws_iam_role.maintenance[0].arn : ""
    deprovision_iam_role_arn = local.has_deprovision ? aws_iam_role.deprovision[0].arn : ""
    break_glass_role_arns    = local.break_glass_role_arns
    custom_role_arns         = local.custom_role_arns
    install_inputs           = local.install_inputs
    custom_nested_stacks     = {}
    runner_enabled           = var.runner_enabled
  }, local.all_secret_arns)
}

# Reported through the stack provider rather than a local-exec curl. Two reasons:
# the request now carries an Authorization header, and a token on a curl command
# line would be visible in process arguments and Terraform's log output; and the
# provider owns retries and error reporting instead of shelling out.
#
# phone_home_url comes from the config data source — it embeds a per-stack-version
# identifier the caller has no other way to know, which is what lets this module
# take install_id alone.
#
# The resource lifecycle drives request_type: Create on first apply, Update when
# the payload changes, Delete on destroy. That replaces the always_run timestamp
# trigger, which forced a report on every apply whether or not anything moved.
resource "stack_phone_home" "this" {
  depends_on = [
    module.vpc,
    module.runner,
    aws_iam_role.runner,
    aws_iam_role.provision,
    aws_iam_role.maintenance,
    aws_iam_role.deprovision,
    aws_iam_role.break_glass,
    aws_iam_role.custom,
    aws_secretsmanager_secret_version.auto_generate,
    aws_secretsmanager_secret_version.customer,
  ]

  install_id      = local.nuon_install_id
  phone_home_url  = local.phone_home_url
  phone_home_type = "aws"

  payload = jsonencode(local.phone_home_payload)

  # The effective input values (control plane merged with var.inputs). The API
  # persists these as the install's current inputs, which is what makes tfvars
  # a way to set input values — distinct from `payload`, which records stack
  # outputs.
  inputs = local.install_inputs

  # A hard precondition rather than a `check` block (which only warns, see
  # checks.tf): a typo'd input name would otherwise be silently dropped by the
  # API's own validation and the value never set.
  lifecycle {
    precondition {
      condition     = length(local.unknown_input_keys) == 0
      error_message = "var.inputs contains keys the app does not declare as customer-facing inputs: ${join(", ", local.unknown_input_keys)}. Declared inputs: ${join(", ", keys(data.stack_config.this.install_inputs))}."
    }

    precondition {
      condition     = length(local.missing_required_inputs) == 0
      error_message = "the app requires a value for these inputs: ${join(", ", local.missing_required_inputs)}."
    }

    precondition {
      condition     = length(local.missing_required_secrets) == 0
      error_message = "the app requires a value for these secrets: ${join(", ", local.missing_required_secrets)}."
    }

    precondition {
      condition     = length(local.unknown_role_keys) == 0
      error_message = "var.roles contains keys that match no role: ${join(", ", local.unknown_role_keys)}. Valid keys: ${join(", ", local.display_role_keys)}."
    }
  }
}
