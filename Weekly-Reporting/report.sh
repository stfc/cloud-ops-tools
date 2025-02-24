#!/bin/bash


set -e

openstack compute service list --long -f yaml > "compute_service_list_$(date +%F).yaml"

openstack hypervisor list --long -f yaml > "hypervisor_list_$(date +%F).yaml"

openstack ip availability show 0dc30001-edfb-4137-be76-8e51f38fd650 -f yaml > "floating_ip_list_$(date +%F).yaml"

openstack server list --all-projects --limit -1 -f yaml > "server_list_$(date +%F).yaml"

python3 format_raw_data.py

