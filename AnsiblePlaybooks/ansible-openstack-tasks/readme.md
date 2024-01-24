A set of playbooks for various tasks interacting with OpenStack

# Getting Started

First install ansible into a virtual environment

`python3 -m venv /home/ansible && source /home/ansible/bin/activate`

Then git clone this repo and move into it

`git clone https://github.com/stfc/cloud-ops-tools && cd cloud-ops-tools/AnsiblePlaybooks/ansible-openstack-tasks`

Then install the requirements for this set of ansible playbooks

`ansible-galaxy collection install -r requirements.yml`

Then run the setup playbook to install additionally required packages

`ansible-playbook setup.yml`

You will need to have a clouds.yml file in an appropriate location `~/.config/openstack/clouds.yml` with `dev-admin` and `prod-admin` credentials available

# Retrieving federation mappings

Run the playbook to get idp mappings with the inventory for whichever cloud you want to target (staging first is a good idea)

`ansible-playbook get-idp-mappings.yml -i <inventory>`

This will give you a yaml file in `./files` with each of the mappings listed in a human readable way.

# Updating federation mappings

Copy the template mappings file to new mappings

`cp files/templates/template-mappings.yml files/new-mappings.yml`

Edit the file with the appropriate details for the mapping you are creating

Ensure that you only have one of either groups or projects (it is recommended to use projects going forwards)

Once complete run the playbook to update the idp mappings

`ansible-playbook update-idp-mappings.yml -i <inventory>`

This should return a success and update the mappings in Openstack

Test that your new mapping works.
