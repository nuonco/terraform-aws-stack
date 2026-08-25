# BYOC example

To use this module with Nuon BYOC, override the provider's `api_url`.

```hcl
provider "stack" {
  api_url   = var.api_url
  api_token = var.api_token
}
```
