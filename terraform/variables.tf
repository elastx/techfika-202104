variable "common_name" {
  description = "Common deployment name. Used to differentiate if multiple deployments in same project"
  default     = "cluster1"
  type        = string
}


variable "network_external_net" {
  description = "UUID of an external network to use for floating IP"
  default     = "600b8501-78cb-4155-9c9f-23dfcba88828"
  type        = string
}

variable "network_floating_ip_pool_name" {
  description = "Name of the floating IP pool to use"
  default     = "elx-public1"
  type        = string
}

variable "network_existing_router_id" {
  description = "UUID of an already externally created router to use. null = new router will be created"
  default     = null
  type        = string
}

variable "network_subnet_cidr" {
  description = "Subnet CIDR block. Needs to be unique per deployment"
  default     = "10.71.71.0/24"
  type        = string
}

variable "network_dns_domain" {
  description = "DNS domain for the internal network"
  default     = null
  type        = string
}

variable "network_dns_nameservers" {
  description = "List of DNS name server names used by hosts in this subnet"
  default     = ["8.8.8.8"]
  type        = list(string)
}


variable "sg_egress_rules" {
  description = "List of egress rules"
  default = [
    {
      "remote_ip_prefix" = "0.0.0.0/0"
    },
  ]
  type = list(map(any))
}

variable "sg_ingress_rules" {
  description = "List of ingress rules"
  default = [
    {
      "protocol"         = "tcp"
      "port_range_min"   = 3306
      "port_range_max"   = 3306
      "remote_ip_prefix" = "10.0.0.0/24"
    },
  ]
  type = list(map(any))
}


variable "public_key_path" {
  description = "The path of the ssh pub key"
  default     = "~/.ssh/id_ecdsa.pub"
  type        = string
}

variable "number_of_nodes" {
  description = "How many nodes that should be part of the cluster"
  default     = 1
  type        = number
}

variable "node_az_list" {
  description = "List of Availability Zones you would like to use"
  default     = ["sto1", "sto2", "sto3"]
  type        = list(string)
}

variable "node_flavor_id" {
  description = "Use 'openstack flavor list' command to see available flavors. Default is 3f73fc93-ec61-4808-88df-2580d94c1a9b (v1-standard-2)"
  default     = "3f73fc93-ec61-4808-88df-2580d94c1a9b"
  type        = string
}

variable "node_image_name" {
  description = "The image to use"
  default     = "ubuntu-20.04-server-latest"
  type        = string
}

variable "node_boot_volume_size_in_gb" {
  description = "How large should root volume be. 0 = use ephemeral instead"
  default     = 0
  type        = number
}

variable "node_boot_volume_type" {
  description = "If booting from volume, which volume type to use"
  default     = "16k-IOPS"
  type        = string
}

variable "node_db_volume_size_in_gb" {
  description = "How large should db volume be"
  default     = 100
  type        = number
}

variable "node_db_volume_type" {
  description = "Volume type to use"
  default     = "16k-IOPS"
  type        = string
}

variable "node_ssh_user" {
  description = "SSH username"
  default     = "ubuntu"
  type        = string
}

variable "node_supplementary_groups" {
  description = "Supplementary ansible groups"
  default     = ""
  type        = string
}
