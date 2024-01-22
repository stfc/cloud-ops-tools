#! /bin/bash

server_UUID=$(curl  http://169.254.169.254/openstack/latest/meta_data.json -s  | grep -ioP .{8}-.{4}-.{4}-.{4}-.{12})
vm_info=$(openstack server show $server_UUID)
echo $vm_info | grep -ioP "\w*.nubes.rl.ac.uk" | head -1
echo $vm_info | grep -ioP "flavor\s\|\s\S*" | cut -c 10-
echo $vm_info | grep -ioP "image\s\|\s\S*" | cut -c 9-


