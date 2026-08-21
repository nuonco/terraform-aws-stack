output "account_id" {
  value = module.install_stack.account_id
}

output "vpc_id" {
  value = module.install_stack.vpc_id
}

output "runner_asg_name" {
  value = module.install_stack.runner_asg_name
}

output "maintenance_iam_role_arn" {
  value = module.install_stack.maintenance_iam_role_arn
}

output "secret_arns" {
  value = module.install_stack.secret_arns
}
