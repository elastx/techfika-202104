resource "openstack_networking_router_v2" "res" {
  count               = var.router_id == null ? 1 : 0
  name                = "${var.common_name}-router"
  admin_state_up      = true
  external_network_id = var.external_net
}

data "openstack_networking_router_v2" "res" {
  count     = var.router_id != null ? 1 : 0
  router_id = var.router_id
}

resource "openstack_networking_network_v2" "res" {
  count          = 1
  name           = "${var.common_name}-internal"
  admin_state_up = true
  dns_domain     = var.dns_domain != null ? var.dns_domain : null
}

resource "openstack_networking_subnet_v2" "res" {
  count           = 1
  name            = "${var.common_name}-internal-network"
  cidr            = var.subnet_cidr
  dns_nameservers = var.dns_nameservers
  ip_version      = 4
  network_id      = openstack_networking_network_v2.res[count.index].id
}

resource "openstack_networking_router_interface_v2" "res" {
  count     = 1
  router_id = "%{if openstack_networking_router_v2.res != []}${openstack_networking_router_v2.res[count.index].id}%{else}${var.router_id}%{endif}"
  subnet_id = openstack_networking_subnet_v2.res[count.index].id
}

resource "openstack_networking_secgroup_v2" "res" {
  count                = 1
  name                 = "${var.common_name}-sg"
  delete_default_rules = true
  description          = "${var.common_name} - Terraform maintained"
}

resource "openstack_networking_secgroup_rule_v2" "self_egress" {
  count             = 1
  direction         = "egress"
  ethertype         = "IPv4"
  remote_group_id   = openstack_networking_secgroup_v2.res[0].id
  security_group_id = openstack_networking_secgroup_v2.res[0].id
}

resource "openstack_networking_secgroup_rule_v2" "self_ingress" {
  count             = 1
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = openstack_networking_secgroup_v2.res[0].id
  security_group_id = openstack_networking_secgroup_v2.res[0].id
}

resource "openstack_networking_secgroup_rule_v2" "egress" {
  count             = length(var.egress_rules)
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = lookup(var.egress_rules[count.index], "protocol", null)
  port_range_min    = lookup(var.egress_rules[count.index], "port_range_min", null)
  port_range_max    = lookup(var.egress_rules[count.index], "port_range_max", null)
  remote_group_id   = lookup(var.egress_rules[count.index], "remote_group_id", null)
  remote_ip_prefix  = lookup(var.egress_rules[count.index], "remote_ip_prefix", null)
  security_group_id = openstack_networking_secgroup_v2.res[0].id
}

resource "openstack_networking_secgroup_rule_v2" "ingress" {
  count             = length(var.ingress_rules)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = lookup(var.ingress_rules[count.index], "protocol", null)
  port_range_min    = lookup(var.ingress_rules[count.index], "port_range_min", null)
  port_range_max    = lookup(var.ingress_rules[count.index], "port_range_max", null)
  remote_group_id   = lookup(var.ingress_rules[count.index], "remote_group_id", null)
  remote_ip_prefix  = lookup(var.ingress_rules[count.index], "remote_ip_prefix", null)
  security_group_id = openstack_networking_secgroup_v2.res[0].id
}
