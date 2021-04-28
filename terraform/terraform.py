#!/usr/bin/env python3
#
# Copyright 2015 Cisco Systems, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# original: https://github.com/CiscoCloud/terraform.py

"""\
Dynamic inventory for Terraform - finds all `.tfstate` files below the working
directory and generates an inventory based on them.
"""
import argparse
from collections import defaultdict
import random
from functools import wraps
import json
import os
import re

VERSION = '0.1'

## READ RESOURCES
PARSERS = {}

def parses(prefix):
    def inner(func):
        PARSERS[prefix] = func
        return func

    return inner


def tfstates(root=None):
    root = root or os.getcwd()
    for dirpath, _, filenames in os.walk(root):
        for name in filenames:
            if os.path.splitext(name)[-1] == '.tfstate':
                yield os.path.join(dirpath, name)


def iterresources(filenames):
    for filename in filenames:
        with open(filename, 'r') as json_file:
            state = json.load(json_file)
            tf_version = state['version']
            if tf_version == 4:
                for resource in state['resources']:
                    name = resource['provider']
                    for instance in resource['instances']:
                        key = "{}.{}".format(resource['type'], resource['name'])
                        if 'index_key' in instance:
                            key = "{}.{}".format(key, instance['index_key'])
                        data = {}
                        data['type'] = resource['type']
                        data['provider'] = resource['provider']
                        data['attributes'] = instance['attributes']
                        yield name, key, data
            else:
                raise KeyError('tfstate version %d not supported' % tf_version)


def iterhosts(resources):
    '''yield host tuples of (name, attributes, groups)'''
    for module_name, key, resource in resources:
        resource_type, name = key.split('.', 1)
        try:
            parser = PARSERS[resource_type]
        except KeyError:
            continue

        yield parser(resource, module_name)


def iterips(resources):
    '''yield ip tuples of (instance_id, ip)'''
    for module_name, key, resource in resources:
        resource_type, name = key.split('.', 1)
        if resource_type == 'openstack_compute_floatingip_associate_v2':
            yield openstack_floating_ips(resource)


def _parse_prefix(source, prefix, sep='.'):
    for compkey, value in list(source.items()):
        try:
            curprefix, rest = compkey.split(sep, 1)
        except ValueError:
            continue

        if curprefix != prefix or rest == '#':
            continue

        yield rest, value


def parse_dict(source, prefix, sep='.'):
    return dict(_parse_prefix(source, prefix, sep))


def openstack_floating_ips(resource):
    raw_attrs = resource['attributes']
    return raw_attrs['instance_id'], raw_attrs['floating_ip']


@parses('openstack_compute_instance_v2')
def openstack_host(resource, module_name):
    raw_attrs = resource['attributes']
    name = raw_attrs['name']
    groups = []

    attrs = {
        'access_ip_v4': raw_attrs['access_ip_v4'],
        'access_ip_v6': raw_attrs['access_ip_v6'],
        'access_ip': raw_attrs['access_ip_v4'],
        'ip': raw_attrs['network'][0]['fixed_ip_v4'],
        'flavor': parse_dict(raw_attrs, 'flavor',
                             sep='_'),
        'id': raw_attrs['id'],
        'image': parse_dict(raw_attrs, 'image',
                            sep='_'),
        'key_pair': raw_attrs['key_pair'],
        'metadata': raw_attrs['metadata'],
        'network': raw_attrs['network'][0],
        'region': raw_attrs.get('region', ''),
        'security_groups': raw_attrs['security_groups'],
        # ansible
        'ansible_ssh_port': 22,
        # workaround for an OpenStack bug where hosts have a different domain
        # after they're restarted
        'host_domain': 'novalocal',
        'use_host_domain': True,
        # generic
        'public_ipv4': raw_attrs['access_ip_v4'],
        'private_ipv4': raw_attrs['access_ip_v4'],
        'provider': 'openstack',
    }

    if 'floating_ip' in raw_attrs:
        attrs['private_ipv4'] = raw_attrs['network'][0]['fixed_ip_v4']

    try:
        if 'prefer_ipv6' in raw_attrs['metadata'] and raw_attrs['metadata']['prefer_ipv6'] == "1":
            attrs.update({
                'ansible_ssh_host': re.sub("[\[\]]", "", raw_attrs['access_ip_v6']),
                'publicly_routable': True,
            })
        else:
            attrs.update({
                'ansible_ssh_host': raw_attrs['access_ip_v4'],
                'publicly_routable': True,
            })
    except (KeyError, ValueError):
        attrs.update({'ansible_ssh_host': '', 'publicly_routable': False})

    # attrs specific to Ansible
    if 'ssh_user' in raw_attrs['metadata']:
        attrs['ansible_ssh_user'] = raw_attrs['metadata']['ssh_user']

    # add groups based on attrs
    groups.append('os_image=' + attrs['image']['name'])
    groups.append('os_flavor=' + attrs['flavor']['name'])
    groups.extend('os_metadata_%s=%s' % item
                  for item in list(attrs['metadata'].items()))
    groups.append('os_region=' + attrs['region'])

    # groups used in galera ansible playbook
    for group in attrs['metadata'].get('ansible_groups', "").split(","):
        groups.append(group)

    return name, attrs, groups


def iter_host_ips(hosts, ips):
    '''Update hosts that have an entry in the floating IP list'''
    for host in hosts:
        host_id = host[1]['id']

        if host_id in ips:
            ip = ips[host_id]

            host[1].update({
                'access_ip_v4': ip,
                'access_ip': ip,
                'public_ipv4': ip,
                'ansible_ssh_host': ip,
            })

        if 'use_access_ip' in host[1]['metadata'] and host[1]['metadata']['use_access_ip'] == "0":
                host[1].pop('access_ip')

        yield host


## QUERY TYPES
def query_host(hosts, target):
    for name, attrs, _ in hosts:
        if name == target:
            return attrs

    return {}


def query_list(hosts):
    groups = defaultdict(dict)
    meta = {}

    for name, attrs, hostgroups in hosts:
        for group in set(hostgroups):
            # Ansible 2.6.2 stopped supporting empty group names: https://github.com/ansible/ansible/pull/42584/commits/d4cd474b42ed23d8f8aabb2a7f84699673852eaf
            # Empty group name defaults to "all" in Ansible < 2.6.2 so we alter empty group names to "all"
            if not group: group = "all"

            groups[group].setdefault('hosts', [])
            groups[group]['hosts'].append(name)

        meta[name] = attrs

    groups['_meta'] = {'hostvars': meta}
    return groups


def query_hostfile(hosts):
    out = ['## begin hosts generated by terraform.py ##']
    out.extend(
        '{}\t{}'.format(attrs['ansible_ssh_host'].ljust(16), name)
        for name, attrs, _ in hosts
    )

    out.append('## end hosts generated by terraform.py ##')
    return '\n'.join(out)


def main():
    parser = argparse.ArgumentParser(
        __file__, __doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter, )
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument('--list',
                       action='store_true',
                       help='list all variables')
    modes.add_argument('--host', help='list variables for a single host')
    modes.add_argument('--version',
                       action='store_true',
                       help='print version and exit')
    modes.add_argument('--hostfile',
                       action='store_true',
                       help='print hosts as a /etc/hosts snippet')
    parser.add_argument('--pretty',
                        action='store_true',
                        help='pretty-print output JSON')
    parser.add_argument('--nometa',
                        action='store_true',
                        help='with --list, exclude hostvars')
    default_root = os.environ.get('TERRAFORM_STATE_ROOT',
                                  os.path.abspath(os.path.dirname(__file__)))
    parser.add_argument('--root',
                        default=default_root,
                        help='custom root to search for `.tfstate`s in')

    args = parser.parse_args()

    if args.version:
        print('%s %s' % (__file__, VERSION))
        parser.exit()

    hosts = iterhosts(iterresources(tfstates(args.root)))

    # Perform a second pass on the file to pick up floating_ip entries to update the ip address of referenced hosts
    ips = dict(iterips(iterresources(tfstates(args.root))))

    if ips:
        hosts = iter_host_ips(hosts, ips)

    if args.list:
        output = query_list(hosts)
        if args.nometa:
            del output['_meta']
        print(json.dumps(output, indent=4 if args.pretty else None))
    elif args.host:
        output = query_host(hosts, args.host)
        print(json.dumps(output, indent=4 if args.pretty else None))
    elif args.hostfile:
        output = query_hostfile(hosts)
        print(output)

    parser.exit()


if __name__ == '__main__':
    main()
