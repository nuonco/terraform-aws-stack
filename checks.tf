# This module intentionally declares no `provider "aws"` or `provider "stack"`
# block so that callers can compose it with count/for_each and pass in aliased
# providers. The tradeoff is that the AWS provider's region is set by the
# caller, independently of the region the Nuon control plane believes this
# install belongs to.
#
# A mismatch is quiet but damaging — resources would be created in one region
# while outputs, the phone-home payload, and the telemetry-export secret ARN
# all reference another. This surfaces it at plan time, validated against the
# control plane rather than against another caller-supplied value.
#
# A `check` block warns without failing the apply, which is deliberate: an
# operator overriding the region on purpose should not be hard-blocked.
data "aws_region" "current" {}

check "aws_region_matches_stack_config" {
  assert {
    condition     = data.aws_region.current.region == local.region
    error_message = "The AWS provider is configured for ${data.aws_region.current.region}, but the Nuon control plane reports this install's region as ${local.region}. Point the aws provider at ${local.region}."
  }
}
