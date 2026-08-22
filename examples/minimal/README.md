# Minimal example

The smallest working configuration: a single `install_id`. Runner details, IAM
permissions, roles, install inputs, and secret metadata are all read from the
Nuon control plane.

Both the `aws` and `stack` providers are configured **here**, not inside the
module. The `stack` provider needs credentials — an `api_token`, or `org_id`
alone to exchange an ambient OIDC token in CI.

```bash
terraform init
terraform apply
```
