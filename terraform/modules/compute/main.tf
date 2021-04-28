data "openstack_images_image_v2" "res" {
  name = var.image_name
}

resource "openstack_compute_keypair_v2" "res" {
  name       = var.common_name
  public_key = chomp(file(var.public_key_path))
}

resource "openstack_compute_servergroup_v2" "res" {
  name     = "node-srvgrp"
  policies = ["anti-affinity"]
}

resource "openstack_blockstorage_volume_v3" "db_volume" {
  count             = var.number_of_nodes
  availability_zone = element(var.az_list, count.index)
  name              = "${var.common_name}-db_volume-node-${count.index + 1}"
  size              = var.db_volume_size_in_gb
  volume_type       = var.db_volume_type
}

resource "openstack_blockstorage_volume_v3" "boot_volume" {
  count             = var.boot_volume_size_in_gb > 0 ? var.number_of_nodes : 0
  availability_zone = element(var.az_list, count.index)
  name              = "${var.common_name}-boot_volume-node-${count.index + 1}"
  image_id          = data.openstack_images_image_v2.res.id
  size              = var.boot_volume_size_in_gb
  volume_type       = var.boot_volume_type
}

resource "openstack_compute_instance_v2" "res" {
  count             = var.number_of_nodes
  name              = "${var.common_name}-node-${count.index + 1}"
  availability_zone = element(var.az_list, count.index)
  image_name        = var.image_name
  flavor_id         = var.flavor_id
  key_pair          = openstack_compute_keypair_v2.res.name

  dynamic "block_device" {
    for_each = var.boot_volume_size_in_gb > 0 ? [var.image_name] : []
    content {
      uuid                  = openstack_blockstorage_volume_v3.boot_volume[count.index].id
      destination_type      = "volume"
      boot_index            = 0
      source_type           = "volume"
    }
  }

  metadata = {
    ansible_groups = "galera_cluster_group,${var.supplementary_groups}"
    ssh_user       = var.ssh_user
  }

  network {
    name = var.network_name
  }

  security_groups = [var.security_group_name]

  scheduler_hints {
    group = openstack_compute_servergroup_v2.res.id
  }
}

resource "openstack_compute_volume_attach_v2" "res" {
  count       = var.number_of_nodes
  instance_id = element(openstack_compute_instance_v2.res.*.id, count.index)
  volume_id   = element(openstack_blockstorage_volume_v3.db_volume.*.id, count.index)
}

resource "openstack_compute_floatingip_associate_v2" "res" {
  count                 = var.number_of_nodes
  floating_ip           = var.floating_ip_list[count.index]
  instance_id           = element(openstack_compute_instance_v2.res[*].id, count.index)
  wait_until_associated = true
}
