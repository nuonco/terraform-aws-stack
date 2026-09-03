variable "prefix" {
  type        = string
  description = "Resource name prefix (typically the Nuon install ID)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

variable "enable_dns_firewall" {
  type        = bool
  default     = false
  description = "Enable Route 53 Resolver DNS Firewall. When true, outbound DNS is blocked unless listed in egress_allowed_domains."
}

variable "egress_allowed_domains" {
  type        = list(string)
  default     = []
  description = "Domains allowed through the DNS firewall (e.g. [\"api.nuon.co\", \".nuon.co\"]). Ignored unless enable_dns_firewall is true."
}
