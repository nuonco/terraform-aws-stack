output "vpc_id" {
  value = module.aws_stack.vpc_id
}

output "runner_subnet" {
  value = module.aws_stack.runner_subnet
}

output "maintenance_iam_role_arn" {
  value = module.aws_stack.maintenance_iam_role_arn
}
