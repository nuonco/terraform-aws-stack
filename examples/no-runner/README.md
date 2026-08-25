# No-runner example

Networking, IAM, and secrets without a runner — `runner_enabled = false` skips
the launch template, ASG, and log group.

Useful for validating IAM and networking before bringing a runner online. This
is not a working install on its own: the runner is what polls the control plane
and executes jobs. See [`../minimal`](../minimal) for the normal case.

Both the `aws` and `stack` providers are configured **here**, not inside the
module.

```bash
terraform init
terraform apply
```
