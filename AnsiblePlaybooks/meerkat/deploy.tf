terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
    ansible = {
      source = "ansible/ansible"
      version = "~> 1.1.0"
    }
  }
}

provider "openstack" {
  cloud = "openstack"	# Uses the section called “openstack” from our app creds
}



locals {
  my_product = {for val in setproduct(var.flavor_name, var.image_name):
    "${val[0]}-${val[1]}" => val}
}

resource "openstack_compute_instance_v2" "Instance" {
  for_each = local.my_product
  name = "${var.instance_name}-${each.value[0]}-${each.value[1]}"
  image_name = each.value[1]
  flavor_name = each.value[0]
  key_pair = var.keypair_name
  security_groups = var.security_groups
  network {
    name = var.network_name
  }
  metadata = {
    group = var.VM_group
  }
#    provisioner "local-exec" {
#         command = "ANSIBLE_HOST_KEY_CHECKING=False ansible -m wait_for_connection -i staging-openstack.yaml ${self.name}"
#    }
#    provisioner "local-exec" {
#         command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i staging-openstack.yaml -l ${self.name} meerkat.yaml --tags storage"
#    }
}

resource "openstack_blockstorage_volume_v3" "volumes" {
  count = length(local.my_product)
  name = format("vol-%02d", count.index + 1)
  region = "RegionOne"
  description = "volume for benchmark testing"
  size = 15
}


locals {
  vm_ids = [ for val in openstack_compute_instance_v2.Instance : val.id]
  vm_names = [ for val in openstack_compute_instance_v2.Instance : val.name]
  volume_ids = [ for val in openstack_blockstorage_volume_v3.volumes : val.id]
}

resource "openstack_compute_volume_attach_v2" "vol_attach" {
  count = length(openstack_compute_instance_v2.Instance)
  instance_id = local.vm_ids[count.index]
  volume_id = local.volume_ids[count.index]

     provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i staging-openstack.yaml -l ${local.vm_names[count.index]} /home/diz41711/cloud-ops-tools/AnsiblePlaybooks/meerkat/meerkat.yaml --tags storage"
   }
}

#resource "openstack_compute_volume_attach_v2" "vol_attach" {
#  count = length(openstack_compute_instance_v2.Instance)
#  instance_id = local.vm_ids[count.index]
#  volume_id = local.volume_ids[count.index]
#}

#locals {
#  vm_names = [ for val in openstack_compute_instance_v2.Instance: val.id]
#}

#resource "ansible_playbook" "playbook" {
#  playbook = "/home/diz41711/cloud-ops-tools/AnsiblePlaybooks/meerkat/meerkat.yaml"
#  name = "meerkat-l3.tiny-ubuntu-focal-20.04-nogui"
#  groups = [ var.VM_group ]
#  tags = [ "storage" ]
#  verbosity = 3
#}












