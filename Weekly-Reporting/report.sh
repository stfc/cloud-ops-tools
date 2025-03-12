#!/bin/bash

set -e

echo "Checking if a development or production openrc was sourced and setting the FIP subnet appropriately."
echo "..."
if [[ $OS_AUTH_URL == *"dev"*  ]]; then
  fip_subnet="0dc30001-edfb-4137-be76-8e51f38fd650"
else
  fip_subnet="5283f642-8bd8-48b6-8608-fa3006ff4539"
fi

echo "Finding all OpenStack compute service hosts and writing to -> compute_service_list_$(date +%F).yaml"
echo "..."
openstack compute service list --long -f yaml > "compute_service_list_$(date +%F).yaml"

echo "Finding all OpenStack Hypervisor hosts and writing to -> hypervisor_list_$(date +%F).yaml"
echo "..."
openstack hypervisor list --long -f yaml > "hypervisor_list_$(date +%F).yaml"

echo "Checking floating IP availability and writing to -> floating_ip_list_$(date +%F).yaml"
echo "..."
openstack ip availability show "${fip_subnet}" -f yaml > "floating_ip_list_$(date +%F).yaml"

echo "Finding all OpenStack virtual machines and writing to -> server_list_$(date +%F).yaml"
echo "..."
openstack server list --all-projects --limit -1 -f yaml > "server_list_$(date +%F).yaml"

echo "Formatting data and writing to weekly-report-$(date +%F).yaml"
echo "..."
python3 format_raw_data.py

echo "Done."
