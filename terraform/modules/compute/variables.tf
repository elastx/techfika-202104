variable "common_name" {}
variable "az_list" {
  type = list
}
variable "boot_volume_size_in_gb" {}
variable "boot_volume_type" {}
variable "db_volume_size_in_gb" {}
variable "db_volume_type" {}
variable "flavor_id" {}
variable "floating_ip_list" {
  type = list
}
variable "image_name" {}
variable "network_name" {}
variable "number_of_nodes" {}
variable "public_key_path" {}
variable "router_id" {}
variable "security_group_name" {}
variable "ssh_user" {}
variable "supplementary_groups" {}
