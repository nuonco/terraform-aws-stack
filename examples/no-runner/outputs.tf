output "vpc_id" {
  value = module.install_stack.vpc_id
}

output "runner_subnet" {
  value = module.install_stack.runner_subnet
}

output "maintenance_iam_role_arn" {
  value = module.install_stack.maintenance_iam_role_arn
}
