output "floating_ip_list" {
  value = openstack_networking_floatingip_v2.res[*].address
}
