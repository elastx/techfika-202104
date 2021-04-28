variable "common_name" {}
variable "dns_domain" {}
variable "dns_nameservers" {
  type = list
}
variable "external_net" {}
variable "router_id" {}
variable "subnet_cidr" {}

variable "egress_rules" {}
variable "ingress_rules" {}
