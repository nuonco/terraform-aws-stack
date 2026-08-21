# Minimal example

Networking, IAM, and secrets only — `runner_enabled = false` skips the runner.

Both the `aws` and `stack` providers are configured **here**, not inside the
module.

```bash
terraform init
terraform apply
```
