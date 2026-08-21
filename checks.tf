# This module intentionally declares no `provider "aws"` block so that callers
# can compose it with count/for_each and pass in aliased providers. The tradeoff
# is that `var.aws_region` is now decoupled from the provider's actual region:
# nothing forces them to agree.
#
# A mismatch is quiet but damaging — the phone-home payload, the `region`
# output, and the telemetry-export secret ARN in iam.tf would all reference a
# region the resources were not created in. This surfaces it at plan time.
#
# A `check` block warns without failing the apply, which is deliberate: an
# operator overriding the region on purpose should not be hard-blocked.
data "aws_region" "current" {}

check "aws_region_matches_provider" {
  assert {
    condition     = var.aws_region == data.aws_region.current.region
    error_message = "var.aws_region (${var.aws_region}) does not match the configured AWS provider region (${data.aws_region.current.region}). Outputs, the phone-home payload, and Secrets Manager ARNs will reference the wrong region."
  }
}
