variable "prefix" {
  type        = string
  description = "Resource name prefix (typically the Nuon install ID)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}
