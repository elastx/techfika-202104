# Terraform
Default will create:
- 1 node, consisting of:
  - 2 vCPU
  - 8 GB RAM
  - 80 GB unencrypted ephemeral root disk
  - 100 GB encrypted 16k IOPS volume for database

Access:
- You will need to add additional information in order to successfully manage your newly created cluster:
  - Add source IP address, from where you will initialise deployment, in `sg_ingress_rules` configuration block.
  - To access the database you might need to replace `remote_ip_prefix` (or add another rule) in `sg_ingress_rules` configuration block. By default set to `10.0.0.0/24` which is default address range for ELASTX managed Kubernetes clusters.

For ease of use you should create a new file with `.auto.tfvars` as file suffix. Down below follow an example for deploying a 3 node cluster with a router already provisioned inside OpenStack project. Omit `network_existing_router_id` if you want Terraform to create a router for you:

```
network_existing_router_id = "7bc279f5-8295-4a27-9b1d-38b14babae94"

number_of_nodes = 3

sg_ingress_rules = [
  {
    "protocol"         = "tcp"
    "port_range_min"   = 22
    "port_range_max"   = 22
    "remote_ip_prefix" = "217.61.244.21/32"
  },
  {
    "protocol"         = "tcp"
    "port_range_min"   = 3306
    "port_range_max"   = 3306
    "remote_ip_prefix" = "10.0.0.0/24"
  },
]
```

Variables recommended to edit:

| Variable | Description |
| -------- | ----------- |
| `common_name`                 | Default `cluster1`. Used to differentiate if multiple deployments in same project. |
| `network_existing_router_id`  | If you already have an existing router enter UUID for that here. If not leave it be. |
| `network_subnet_cidr`         | Default `10.71.71.0/24`. Change if you have a network that collides. |
| `network_dns_domain`          | Change if you want to use your own dns domain. |
| `network_dns_nameservers`     | Default `8.8.8.8`. Change if you want to use your own DNS nameservers. |
| `sg_egress_rules`             | List of CIDRs that can be accessed from database nodes. Default `0.0.0.0/0` |
| `sg_ingress_rules`            | List of CIDRS that can access database nodes. Default `10.0.0.0/24, port 3306`. You will need to add your own rules for SSH access. |
| `public_key_path`             | Default `~/.ssh/id_ecdsa`. Path to your public key. |
| `number_of_nodes`             | Default `1`. Change if you want to run multi node cluster. |
| `node_flavor_id`              | Default `3f73fc93-ec61-4808-88df-2580d94c1a9b` (v1-standard-2). Change if you want different size on nodes. |
| `node_boot_volume_size_in_gb` | Default `0` (i.e. boot from ephemeral). Set to desired volume size if you want to boot from volume (for example if you want encrypted root disk). |
| `node_boot_volume_type`       | Default `16k-IOPS`. |
| `node_db_volume_size_in_gb`   | In gigabytes. Default `100`. |
| `node_db_volume_type`         | Default `16k-IOPS`. |
| `node_supplementary_groups`   | Used to add additional ansible groups if wanted, comma separated string. Empty by default. |

To deploy you can simply run `make`. However this expects you to run a Linux system. If not then install Terraform on your own and run the standard terraform commands.

