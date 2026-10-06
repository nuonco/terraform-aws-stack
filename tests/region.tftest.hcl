# Checks var.region reaches the stack's regional resources, independent of the
# aws provider's region. Runs against mock providers, so it needs no
# credentials or Nuon API:
#
#   terraform init -backend=false && terraform test

mock_provider "aws" {
  # Mock policy documents render random strings, which aws_iam_role rejects
  # as invalid JSON.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  # The vpc module spreads its subnets over three zones.
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    }
  }
}

mock_provider "stack" {
  mock_data "stack_config" {
    defaults = {
      install_id                 = "inltest"
      org_id                     = "orgtest"
      app_id                     = "apptest"
      runner_id                  = "runtest"
      runner_api_url             = "https://runner.example.com"
      phone_home_url             = "https://runner.example.com/phone-home"
      stack_version_id           = "stvtest"
      custom_stacks_template_url = ""
      install_inputs             = {}
      required_input_names       = []
      sensitive_input_names      = []
      auto_generate_secrets      = []
      secrets                    = {}
      aws = {
        region                             = "eu-west-1"
        vpc_nested_template_url            = ""
        runner_machine_type                = ""
        nuon_support_iam_role_arns         = []
        provision_permissions              = []
        provision_inline_policy_document   = ""
        provision_managed_policy_arns      = []
        maintenance_permissions            = []
        maintenance_inline_policy_document = ""
        maintenance_managed_policy_arns    = []
        deprovision_permissions            = []
        deprovision_inline_policy_document = ""
        deprovision_managed_policy_arns    = []
        break_glass_roles                  = {}
        custom_roles                       = {}
      }
    }
  }
}

variables {
  install_id = "inltest"
}

run "region_overrides_provider" {
  command = plan

  variables {
    region = "eu-west-1"
  }

  assert {
    condition     = aws_secretsmanager_secret.telemetry_export_config.region == "eu-west-1"
    error_message = "root module resources should be created in var.region"
  }

  assert {
    condition     = aws_lb.telemetry[0].region == "eu-west-1"
    error_message = "telemetry resources should be created in var.region"
  }

  assert {
    condition     = data.aws_region.current.region == "eu-west-1"
    error_message = "the region check should look at var.region"
  }
}

run "vpc_module_uses_region" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    prefix = "inltest"
    region = "eu-west-1"
  }

  assert {
    condition     = aws_vpc.main.region == "eu-west-1" && alltrue([for s in aws_subnet.private : s.region == "eu-west-1"])
    error_message = "the vpc module should create its network in var.region"
  }

  assert {
    condition     = aws_nat_gateway.main.region == "eu-west-1"
    error_message = "the vpc module should create its NAT gateway in var.region"
  }
}

run "runner_module_uses_region" {
  command = plan

  module {
    source = "./modules/runner"
  }

  variables {
    prefix                       = "inltest"
    region                       = "eu-west-1"
    vpc_id                       = "vpc-test"
    runner_subnet_id             = "subnet-test"
    runner_security_group        = "sg-test"
    runner_instance_profile_name = "inltest-runner"
    runner_api_url               = "https://runner.example.com"
    runner_id                    = "runtest"
    nuon_install_id              = "inltest"
    instance_type                = "t3a.medium"
  }

  assert {
    condition     = aws_autoscaling_group.runner.region == "eu-west-1" && aws_launch_template.runner.region == "eu-west-1"
    error_message = "the runner module should create its runner in var.region"
  }
}

run "invalid_region" {
  command = plan

  variables {
    region = "not a region"
  }

  expect_failures = [var.region]
}
