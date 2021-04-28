resource "null_resource" "dummy_dependency" {
  triggers = {
    dependency_id = openstack_networking_subnet_v2.res[0].id
  }
}

output "router_id" {
  value = var.router_id == null ? element(concat(openstack_networking_router_v2.res.*.id, [""]), 0) : var.router_id
}

output "network_name" {
  value = openstack_networking_network_v2.res[0].name
  depends_on = [null_resource.dummy_dependency]
}

output "security_group_name" {
  value = openstack_networking_secgroup_v2.res[0].name
}
