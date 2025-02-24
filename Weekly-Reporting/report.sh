#!/bin/bash


set -e

if [[ $OS_AUTH_URL == *"dev"*  ]]; then
  fip_subnet="0dc30001-edfb-4137-be76-8e51f38fd650"
else
  fip_subnet="5283f642-8bd8-48b6-8608-fa3006ff4539"
fi
openstack compute service list --long -f yaml > "compute_service_list_$(date +%F).yaml"

openstack hypervisor list --long -f yaml > "hypervisor_list_$(date +%F).yaml"

openstack ip availability show "${fip_subnet}" -f yaml > "floating_ip_list_$(date +%F).yaml"

openstack server list --all-projects --limit -1 -f yaml > "server_list_$(date +%F).yaml"

python3 format_raw_data.py

