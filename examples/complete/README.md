# Complete example

Provisions the full install stack: VPC, runner ASG, the operation roles the
control plane has configured, and secrets.

Both the `aws` and `stack` providers are configured **here**, not inside the
module. `var.aws_region` must match the region Nuon recorded for this install;
the module warns at plan time if it does not.

```bash
terraform init
terraform apply
```
