galera
=========

This role installs and bootstraps a MariaDB/Galera cluster

Requirements
------------

* An odd number of hosts running Ubuntu 20.04 (similar distributions may work but are untested).

Role Variables
--------------

*galera\_cluster\_group*
A reference to a group containing all the hosts that should be members of the cluster. Since the default value does not really make any sense it is implicitly required.
Default: ""

*galera\_limit\_no\_file*
Hard process file limit.
Default: 32184

Dependencies
------------

None

Example Playbook
----------------

    - hosts: galera\_cluster1
      roles:
        - galera

License
-------

The Unlicense

Author Information
------------------

https://www.elastx.se
