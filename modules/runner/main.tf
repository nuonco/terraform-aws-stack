data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
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
  user_data = <<-EOT
    #!/bin/bash
    set -e
    export NUON_RUNNER_ID=${var.runner_id}
    export NUON_RUNNER_API_URL=${var.runner_api_url}
    export NUON_RUNNER_API_TOKEN=${var.runner_api_token}
    export NUON_INSTALL_ID=${var.nuon_install_id}
    curl -fsSL ${var.runner_init_script_url} | bash
  EOT
}

resource "aws_launch_template" "runner" {
  name_prefix   = "${var.prefix}-runner-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  user_data     = base64encode(local.user_data)

  iam_instance_profile {
    name = var.runner_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.runner_security_group]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.prefix}-runner" })
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

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}-runner"
    propagate_at_launch = true
  }
}
