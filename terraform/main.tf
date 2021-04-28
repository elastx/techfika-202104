module "network" {
  source = "./modules/network"

  common_name     = var.common_name
  dns_domain      = var.network_dns_domain
  dns_nameservers = var.network_dns_nameservers
  egress_rules    = var.sg_egress_rules
  external_net    = var.network_external_net
  ingress_rules   = var.sg_ingress_rules
  router_id       = var.network_existing_router_id
  subnet_cidr     = var.network_subnet_cidr
}

module "floating_ip" {
  source = "./modules/floating_ip"

  floating_ip_count     = var.number_of_nodes
  floating_ip_pool_name = var.network_floating_ip_pool_name
  router_id             = module.network.router_id
}

module "compute" {
  source = "./modules/compute"

  common_name            = var.common_name
  az_list                = var.node_az_list
  boot_volume_size_in_gb = var.node_boot_volume_size_in_gb
  boot_volume_type       = var.node_boot_volume_type
  db_volume_size_in_gb   = var.node_db_volume_size_in_gb
  db_volume_type         = var.node_db_volume_type
  flavor_id              = var.node_flavor_id
  floating_ip_list       = module.floating_ip.floating_ip_list
  image_name             = var.node_image_name
  network_name           = module.network.network_name
  number_of_nodes        = var.number_of_nodes
  public_key_path        = var.public_key_path
  router_id              = module.network.router_id
  security_group_name    = module.network.security_group_name
  ssh_user               = var.node_ssh_user
  supplementary_groups   = var.node_supplementary_groups
}

output "nodes_map" {
  value = module.compute.nodes_map
}
