# Complete example: runner enabled, all three operation roles, break-glass and
# custom roles, and both auto-generated and caller-supplied secrets.

module "install_stack" {
  source = "../../"

  aws_region                 = var.aws_region
  nuon_install_id            = var.nuon_install_id
  nuon_org_id                = var.nuon_org_id
  nuon_app_id                = var.nuon_app_id
  runner_api_url             = var.runner_api_url
  runner_id                  = var.runner_id
  phone_home_url             = var.phone_home_url
  nuon_support_iam_role_arns = var.nuon_support_iam_role_arns

  runner_enabled       = true
  runner_instance_type = "t3.large"

  # Operation roles. `*_inline_policy_document` takes precedence over the
  # `*_permissions` shorthand when both are set.
  provision_managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]

  maintenance_permissions = [
    "eks:Describe*",
    "eks:List*",
    "ec2:Describe*",
  ]

  deprovision_inline_policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DeleteCluster", "ec2:TerminateInstances"]
      Resource = "*"
    }]
  })

  # Disabled by default; only created when enabled = true.
  break_glass_roles = {
    incident-response = {
      enabled             = true
      managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }

  custom_roles = {
    app-operator = {
      enabled     = true
      permissions = ["s3:GetObject", "s3:PutObject"]
    }
  }

  install_inputs = {
    cluster_name = "example-cluster"
  }

  auto_generate_secrets = ["db_password"]

  secrets = {
    api_key = {
      description = "Third-party API key"
      required    = true
      value       = "replace-me"
    }
  }
}
