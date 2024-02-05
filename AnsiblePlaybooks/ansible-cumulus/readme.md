This is for configuring STFC Cloud switches with Cumulus 5.x

It currently depends on using Alex Dibbo's version of the ansible nvue collection which is installed using the requirements.yml

# Getting Started

First install ansible into a virtual environment

`python3 -m venv /home/ansible && source /home/ansible/bin/activate`

Then git clone this repo and move into it

`git clone https://github.com/stfc/cloud-ops-tools && cd cloud-ops-tools/AnsiblePlaybooks/ansible-cumulus`

Then install the requirements for this set of ansible playbooks

`ansible-galaxy collection install -r requirements.yml`

Then run the setup playbook to install additionally required packages

`ansible-playbook setup.yml`

# Adding a new switch

Add the name (FQDN) of the new switch to the appropriate group in the production inventory

Create a new file in the `host_vars` directory based on the template in the same directory
