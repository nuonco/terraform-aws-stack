# terraform-aws-stack

Terraform module for provisioning a [Nuon](https://nuon.co) install stack in AWS. It is meant to be applied by a customer against their own AWS account. It provisions a dedicated VPC and an EC2 instance to host the Nuon runner. The runner polls the Nuon control plane for jobs and executes them locally using scoped IAM roles.

## Usage

Import the Nuon Stack provider, then provide an install ID.
Provide the required inputs and secrets, and optionally enable or disable roles.

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "stack" {}

module "aws_stack" {
  source  = "nuonco/stack/aws"
  version = "~> 0.1"

  install_id = var.install_id

  inputs = {
    instance_type = "t3a.medium"
  }

  secrets = {
    license_key = { value = var.license_key }
  }

  roles = {
    "break-glass" = true
  }
}
```

## Architecture

![AWS install stack architecture](https://raw.githubusercontent.com/nuonco/terraform-aws-stack/main/docs/architecture.svg)

## Network topology

| Network          | CIDR             | AZ        | Notes                                |
| ---------------- | ---------------- | --------- | ------------------------------------ |
| VPC              | `10.128.0.0/16`  | —         | DNS support + hostnames enabled      |
| Public subnet A  | `10.128.0.0/24`  | AZ 0      | hosts the NAT Gateway; routes to IGW |
| Public subnet B  | `10.128.16.0/24` | AZ 1      | routes to IGW                        |
| Private subnet A | `10.128.1.0/24`  | AZ 0      | routes to NAT                        |
| Private subnet B | `10.128.17.0/24` | AZ 1      | routes to NAT                        |
| Runner subnet    | `10.128.2.0/24`  | AZ 0 only | shares the private route table       |

- Subnets are tagged `network.nuon.co/domain` = `public` / `internal` / `runner` and `visibility` = `public` / `private`, so downstream components (e.g. EKS, load balancers) can discover them.
- There is a **single NAT Gateway** in public subnet A. Both private subnets and the runner subnet share one private route table, so AZ-B traffic crosses AZs to reach the NAT and there is no NAT redundancy.
- The VPC module gates its `runner_subnet_id` output on the runner route-table association, so the runner instance cannot boot before its default route to the NAT exists.
- The runner requires no inbound connectivity; for the outbound destinations it must reach, see [Runners](https://docs.nuon.co/concepts/runners).

## Runner authentication

On AWS, the Nuon runner authenticates using an Instance Identity Document (IID). The runner proves its identity to the control plane using the EC2 instance identity. For this reason, the region and account ID must be provided up-front when creating an install on AWS.

The authentication process is as follows.

1. User data sets `RUNNER_AUTH_METHOD=iid` on the instance.
1. At boot, the runner reads its **signed instance identity document** from the instance metadata service (IMDS).
1. The runner POSTs the IID, along with its `runner_id` (from the `nuon_runner_id` instance tag), to `/v1/runner-auth/aws-iid`.
1. The control plane verifies the document's signature against AWS's per-region certificates and checks that its account ID matches the account the stack phoned home from.
1. The control plane mints a bearer token.
1. The token is stored at `/opt/nuon/runner/token` (mode 0600) and sent as `Authorization: Bearer` on every subsequent API call.

> [!NOTE]
> When using IID, the `runner_api_token` parameter is not required.

### IMDS

The auth flow (and the tag lookup that precedes it) depends on the instance metadata service at `169.254.169.254`. This is **not outbound traffic** — it's link-local, answered by the hypervisor, and never traverses the security group, route table, or NAT — so it needs no firewall allowance. But it must remain reachable from the runner processes.

- The launch template enforces **IMDSv2** (`http_tokens = required`); don't disable the metadata endpoint on the instance.
- Host-level firewalls or proxy configuration must exclude `169.254.169.254`.
- Containerized processes: this template runs the container with `--network host`, so the default IMDSv2 hop limit of 1 works. If you run the runner on a bridge or overlay network instead, set `http_put_response_hop_limit = 2` — otherwise the IMDSv2 token response is dropped before it reaches the container's network namespace.

## License

[MIT](./LICENSE)
