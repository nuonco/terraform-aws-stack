output "account_id" {
  value = module.aws_stack.account_id
}

output "region" {
  value = module.aws_stack.region
}

output "vpc_id" {
  value = module.aws_stack.vpc_id
}

output "runner_asg_name" {
  value = module.aws_stack.runner_asg_name
}

output "maintenance_iam_role_arn" {
  value = module.aws_stack.maintenance_iam_role_arn
}

output "secret_arns" {
  value = module.aws_stack.secret_arns
}
