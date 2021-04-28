terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 0.14.0"
    }
  }
  required_version = ">= 0.15"
}
