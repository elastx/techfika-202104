resource "null_resource" "dummy_dependency" {
  triggers = {
    dependency_id = var.router_id
  }
}

resource "openstack_networking_floatingip_v2" "res" {
  count      = var.floating_ip_count
  pool       = var.floating_ip_pool_name
  depends_on = [null_resource.dummy_dependency]
}
