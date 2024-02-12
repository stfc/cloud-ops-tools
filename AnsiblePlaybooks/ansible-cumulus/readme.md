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

# Adding a new leaf switch

Add the name (FQDN) of the new leaf switch to the appropriate group in the production inventory

i.e. for a sn2100 which is a leaf in R89 it should be put into the r89leaf_sn2100s group

Create a new file in the `host_vars` directory based on the template in the same directory setting the management ip and downstream ip

The template will get you a basic switch configured with the normal unsplit downstream ports for that hardware type.

Commit and get your changes reviewed

# Additional configuration

## Breakout ports

If split ports are needed then set `breakout_ports`

For example:

```
breakout_ports:
  - breakout: 4x
    id: swp1
  - breakout: 4x
    id: swp2
```

## Specific port VLANs

If specific ports need to have the PVID set such as for a ceph backend network then set `bridge_interfaces_pvids`

For example:

```
bridge_interfaces_pvids:
  - id: swp1
    vlan: 451
```

Bear in mind that this does prevent tagged vlans from being used on this port.

# Reinstall a switch

Ensure that the switch you want is ready to be reinstalled

i.e. that doing so wont effect user traffic or that appropriate downtimes have been declared

In the inventory for the switch you want to reinstall set `reinstall: true`

Run the following command to trigger a reinstall:

`ansible-playbook -i production rebuild.yml --ask-vault-pass --limit <hostname>`

This will take 20-30 minutes for the install and configure to be completed

# Update switch software

Ensure that the switch you want is ready to be updated

i.e. that doing so wont effect user traffic or that appropriate downtimes have been declared

In the inventory for the switch you want to reinstall set `update: true`

Run the following command to trigger a update:

`ansible-playbook -i production rebuild.yml --ask-vault-pass --limit <hostname>`

This should be quick but can take 20-30 minutes for the install and configure to be completed

# Update configuration on a single switch

In the inventory for that switch set the appropriate configure variable

i.e. `configured_bridge: false`

Run the playbook to configure that switch

`ansible-playbook -i production configure.yml --ask-vault-pass --limit <hostname>`

Remove the variables you set from the inventory

# Update configuration on a group of switches

In the inventory for that group of switches set the appropriate configure variable

i.e. `configured_bridge: false` in `group_vars/r89leaf_sn2100s.yml`

This will simultaneuosly configure all switches in the group and may be discruptive.

Run the playbook to configure that switch

`ansible-playbook -i production configure.yml --ask-vault-pass --limit <hostname>`

Remove the variables you set from the inventory

# Update configuration on all switches

In the `group_vars/switches.yml` set the appropriate configure variable

i.e. `configured_bridge: false`

This will simultaneuosly configure all switches and may be discruptive.

Run the playbook to configure that switch

`ansible-playbook -i production configure.yml --ask-vault-pass --limit <hostname>`

Remove the variables you set from the inventory
