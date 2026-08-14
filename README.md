# AWS install stack template

This is a Terraform module for provisioning Nuon install stacks in AWS. It is meant to be applied by a customer against their own AWS account. It provisions a dedicated VPC and an EC2 instance to host the Nuon runner. The runner polls the Nuon control plane for jobs and executes them locally using scoped IAM roles.

For more information about Nuon stack templates, see the [Stack templates](../docs/stack-templates.md) doc.

For more information about the Nuon runner, see the [The Nuon runner](../docs/the-nuon-runner.md) doc.

## Architecture

![AWS install stack architecture](docs/architecture.svg)

## Resources

- **VPC & subnets** (`modules/vpc`) – A dedicated VPC with two public and two private subnets spread across 2 AZs, a single-AZ runner subnet, an Internet Gateway, and one NAT Gateway with an Elastic IP.
- **Runner security group** (`modules/vpc`) – Outbound traffic open to `0.0.0.0/0`; inbound traffic allowed only from the security group itself.
- **Runner** (`modules/runner`) – A launch template + Auto Scaling Group running the latest Amazon Linux 2023 AMI on a `t3.medium` (configurable via `runner_instance_type`) with a 30 GB gp3 root volume, IMDSv2 required, and no public IP. Plus a CloudWatch log group `/nuon/<install-id>/runner` (30-day retention).
- **IAM** (`iam.tf`) –
  - **Runner instance role** + instance profile with a least-privilege inline policy, allowing it to assume the provided IAM roles, read its own secrets, write CloudWatch logs, and describe EC2 instance tags (the init script reads its config from instance tags).
  - **Operation roles**, trusted by the Nuon support roles and the runner. The runner assumes these per-job — it holds no standing workload permissions itself. Each is created only if the customer allows:
    - **provision** – used by provision workflows and secret syncs
    - **maintenance** – used by everything else (the default)
    - **deprovision** – used by deprovision workflows
  - **Break-glass roles** – optional, created from a map keyed by role name and gated by `enabled = true`.
  - **Custom roles** – optional app-operation roles, same shape and gating as break-glass roles.
- **Secrets** (`secrets.tf`) – AWS Secrets Manager entries named `<install-id>-<name>` for auto-generated secrets (63-char random values) and customer-provided secrets, plus an **empty** `nuon/<install-id>/telemetry-export-config` secret whose value the customer uploads out-of-band (see [Telemetry export](../docs/the-nuon-runner.md#telemetry-export-optional)).
- **Phone home** (`phone_home.tf`) – A `local-exec` provisioner that POSTs provisioning results (outputs, install inputs) back to Nuon on every apply.

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
- The runner requires no inbound connectivity; for the outbound destinations it must reach, see [The Nuon runner → Network requirements](../docs/the-nuon-runner.md#network-requirements).

## Authentication

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
