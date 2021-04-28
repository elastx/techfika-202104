This repo contains a bunch of playbooks and a role to manage MariaDB/Galera clusters

Requirements
------------

* An odd number of hosts running Ubuntu 20.04 (similar distributions may work but are untested).
* Ansible 2.9.9

For tests:
* An OpenStack cloud
* Molecule 3.0.4
* python-openstackclient 5.2.1

Usage
-----

Creating a cluster
------------------
Create an inventory containing the nodes you wish to include in the cluster, make sure there is a group containing those nodes. Set the *galera_cluster_group* variable for the nodes to the name of the group containg the cluster nodes.
For example:

    galera1
    galera2
    galera3

    [galera_cluster1]
    galera1
    galera2
    galera3

    [galera_cluster1:vars]
    galera_cluster_group: galera_cluster1

The run the create-cluster.yml playbook like so:

    ansible-playbook -i ../terraform/terraform.py create-cluster.yml

This playbook can also be used if you've lost one or more cluster nodes and wish to add new nodes. Provided the cluster still has quorum just run the playbook as above and the new nodes will be added to the cluster.

Reconfigure
-----------
Modify the server.j2 template to override configuration for MariaDB. Then re-run the create-cluster.yml playbook to apply the configuration.

Backup
------
The galera role includes two backup scripts, one for full and one for incremental backups:
* /usr/local/bin/galera-full-backup
* /usr/local/bin/galera-incremental-backup

They can be utilized to create hot online backups of the database and can be scheduled using cron if desired. Backups end up in:
* /var/mariadb/full-YYYY-MM-DDTHH:MM
* /var/mariadb/incremental-YYYY-MM-DDTHH:MM

The incremental backup script automatically finds the previous backup to base its increment on based on the contents of */var/mariadb*.

*NB* There needs to be a full backup present before running the incremental backup script.

By setting the variables *galera_full_backup* and *galera_incremental_backup* cron jobs for running full and incremental backups can be created as well. Both variables are dicts and the following keys can be used to specify the desired behaviour:
    minute
    hour
    day
    weekday
    month
    state
    host (required - Used to specify which host to run backups on)

See the documentation for the [Ansible cron module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/cron_module.html) for further reference.

Swift
-----
An example playbook and script for transfering backups to swift is provided. Set the following variables:
    swift_project_id
    swift_username
    swift_password
    swift_cron

And run the swift-cron.yml playbook.
    ansible-playbook -i ../terraform/terraform.py swift-cron.yml

The script will select the latest backup to transfer.

Restore from backup
-------------------
If the cluster is still operational there should be no need to restore from backup. However if you really need to restore the procedure is along these lines:

* Stop mariadb on all nodes (this will decommission the cluster)
* Get a hold of the backup sets you wish to use for restore (the complete set of full + incremental)
* Make the backup point in time consistent by running *mariabackup --prepare*
    mariabackup --prepare --target-dir=/var/mariadb/full-YYYY-MM-DDTHH:MM
    mariabackup --prepare --target-dir=/var/mariadb/full-YYYY-MM-DDTHH:MM --incremental-dir=/var/mariadb/incremental-YYYY-MM-DDTHH:MM
    ...
    Repeat for every incremental backup you wish to apply
* Restore the backup
    mariabackup --copy-back --target-dir=/var/mariadb/full-YYYY-MM-DDTHH:MM
* Restore permissions
    chown -R mysql:mysql /var/lib/mysql
* Run the re-bootstrap.yml playbook with some special parameters
    ansible-playbook -i ../terraform/terraform.py re-bootstrap.yml --skip-tags seqno --tags "all,never"
* Be happy!


Recovering quorum
-----------------
In the unlikely event of loosing quorum use the recover-quorum.yml playbook to recover it. It contains a bunch of safe-guards and should generally be safe to run.

    ansible-playbook -i ../terraform/terraform.py create-cluster.yml

Re-bootstraping a cluster
-------------------------
If all the cluster nodes ever go offline at the same time you will have lost your cluster. To recover, run the re-bootstrap.yml playbook. It too contains a bunch of safe-guards and should generally be safe to run.

    ansible-playbook -i ../terraform/terraform.py re-bootstrap.yml

Testing
-------

The role can be tested by running the *default* molecule scenario.

License
-------

The Unlicense

Author Information
------------------

https://www.elastx.se
