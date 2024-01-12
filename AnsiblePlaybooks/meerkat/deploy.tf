terraform {
			required_version = ">= 0.14.0"
			  required_providers {
			    openstack = {
			      source  = "terraform-provider-openstack/openstack"
			      version = "~> 1.53.0"
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
    provisioner "local-exec" {
         command = "ANSIBLE_HOST_KEY_CHECKING=False ansible -m wait_for_connection -i staging-openstack.yaml ${self.name}"
    }
    provisioner "local-exec" {
         command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i staging-openstack.yaml -l ${self.name} site.yaml"
    }


}
