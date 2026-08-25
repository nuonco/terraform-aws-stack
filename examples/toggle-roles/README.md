# Toggle roles

Customers can toggle the roles the runner uses using the `roles` attribute. This will validte against the roles defined in the app config, ensuring they are using the correct names.

Two common use-cases for this are:

- Disabling the provision role once installation is complete, and the runner no longer needs the permissions it grants.
- Enabling a break-glass role, to provide elevated permissions to resolve incidents.

```hcl
module "aws_stack" {
  source = "../../"

  install_id = var.install_id

  roles = {
    # provision is enabled by default, but can be disabled after installation is complete.
    provision = false

    # break glass roles are disabled by default, but can be enabled to grant elevated access.
    "break-glass" = true
  }
}
```
