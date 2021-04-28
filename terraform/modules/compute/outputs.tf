output "nodes_map" {
  value = zipmap(openstack_compute_instance_v2.res.*.name, openstack_compute_floatingip_associate_v2.res.*.floating_ip)
}
