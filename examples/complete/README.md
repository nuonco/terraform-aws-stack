# Complete example

Provisions the full install stack: VPC, runner ASG, all three operation roles,
a break-glass role, a custom app-operation role, and secrets.

Note that the `aws` provider is configured **here**, not inside the module.

```bash
terraform init
terraform apply
```
