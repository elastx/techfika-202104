# techfika-202104
Provision a production ready Galera cluster using Terraform and Ansible. This project is built to be compatible with [ELASTX public OpenStack cloud](https://elastx.se/). Some key features include:

* Ubuntu 20.04 LTS
* Can be deployed as single node or odd numbered multi node cluster
* High availability
* Encrypted DB volume and optional encrypted root disk
* Configurable security group rules for locking down access
* Backup scripts provided to be scheduled using cron

## Overview
Clone this repository for each cluster you want to make. Deploying Galera using this repository is a 2 stage rocket.

1. Deploy infrastructure using Terraform
2. Install and configure DB using Ansible

Please refer to the [Terraform](terraform/README.md) and [Ansible](ansible/README.md) readme for more in depth documentation.

## Getting started with your first deploy
Down follow some example commands to get you started.

1. Modify `sg_ingress_rules` in `terraform/variables.tf` to add SSH ingress.
2. `pushd terraform; make; popd`
3. `pushd ansible; ansible-playbook -u ubuntu -i ../terraform/terraform.py create-cluster.yml; popd`

## License
[The Unlicense](LICENSE)
