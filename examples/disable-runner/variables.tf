variable "aws_region" {
  type        = string
  description = "Region to configure the aws provider with. Must match the region Nuon has recorded for this install."
}

variable "install_id" {
  type        = string
  description = "Nuon install ID. Identifies which install to configure; not a credential."
}
