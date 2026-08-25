# Disable the runner

Customers can disable the runner by setting the `runner_enabled` attribute to `false`. This will tear down the Runner Auto-Scaling Group, ensuring no runner instance is active, then report the runner is disabled to the Nuon control plane. In response, control plane will reject new workflows, cancel in-progress workflows, and pause scheduled workflows.

```hcl
module "aws_stack" {
  source = "../../"

  install_id = var.install_id

  runner_enabled = false
}
```
