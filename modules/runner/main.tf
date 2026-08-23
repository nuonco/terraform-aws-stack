data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_cloudwatch_log_group" "runner" {
  name              = "/nuon/${var.nuon_install_id}/runner"
  retention_in_days = 30
  tags              = var.tags
}

locals {
  # Pinned to main: this stack is tightly coupled to the init script's tag
  # contract and IID auth flow. Do not version separately.
  runner_init_script_url = "https://raw.githubusercontent.com/nuonco/runner/refs/heads/main/scripts/aws/init-mng-v2.sh"

  # A freshly created NAT GW can take minutes to pass traffic, and user_data
  # runs exactly once — a failed download here leaves an inert instance the ASG
  # never replaces. So the download itself retries until it succeeds, is written
  # to a file before running (a failed `curl | bash` exits 0 without pipefail
  # and looks like success), and a hard failure shuts the instance down so the
  # ASG launches a fresh one instead of keeping a corpse.
  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    export RUNNER_AUTH_METHOD=iid
    if ! curl -fsSL --retry 30 --retry-all-errors --retry-delay 10 --max-time 60 \
        -o /tmp/nuon-runner-init.sh ${local.runner_init_script_url}; then
      /sbin/shutdown -h now "unable to download runner init script; replacing instance"
      exit 1
    fi
    bash /tmp/nuon-runner-init.sh
  EOT

  runner_tags = merge(var.tags, {
    Name                = "${var.prefix}-runner"
    nuon_runner_id      = var.runner_id
    nuon_runner_api_url = var.runner_api_url
    nuon_install_id     = var.nuon_install_id
  })
}

resource "aws_launch_template" "runner" {
  name_prefix   = "${var.prefix}-runner-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  user_data     = base64encode(local.user_data)

  iam_instance_profile {
    name = var.runner_instance_profile_name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.runner_security_group]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.runner_tags
  }
}

resource "aws_autoscaling_group" "runner" {
  name                = "${var.prefix}-runner-asg"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [var.runner_subnet_id]

  launch_template {
    id      = aws_launch_template.runner.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  # ASGs ignore the launch template's tag_specifications when launching
  # instances — only ASG `tag` blocks with propagate_at_launch=true land on
  # the instance. The init script's `get_tag` lookups depend on these.
  dynamic "tag" {
    for_each = local.runner_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
