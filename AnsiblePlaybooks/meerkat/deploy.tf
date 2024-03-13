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

##############################################################################
### Deploy VM instances
##############################################################################

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
}

locals {
  vm_ids = [ for val in openstack_compute_instance_v2.Instance : val.id]
  vm_names = [ for val in openstack_compute_instance_v2.Instance : val.name]
  vm_ips = [for val in openstack_compute_instance_v2.Instance : val.access_ip_v4]
}

##############################################################################
### Deploy manila shares
##############################################################################
resource "openstack_sharedfilesystem_share_v2" "shares" {
  count = var.deploy_manila * length(openstack_compute_instance_v2.Instance)
  name             = format("share-%02d", count.index + 1)
  description      = "manila terraform share"
  share_proto      = "CEPHFS"
  size             = var.share_size
}

# Dummy usernames for inital access rules
resource "random_password" "access_names" {
  count = var.deploy_manila * length(openstack_compute_instance_v2.Instance)
  length = 16
  special = false
}

locals {
  share_ids = [ for val in openstack_sharedfilesystem_share_v2.shares : val.id]
  access_names = [for val in random_password.access_names : val.result]
}

# Needs two sets of access rules, as just using one set gives a permission denied error
resource "openstack_sharedfilesystem_share_access_v2" "share_access" {
  count = var.deploy_manila * length(openstack_compute_instance_v2.Instance)
  share_id     = local.share_ids[count.index]
  access_type  = "cephx"
  access_to = local.access_names[count.index]
  access_level = "rw"
  depends_on = [openstack_sharedfilesystem_share_v2.shares]
}

resource "openstack_sharedfilesystem_share_access_v2" "share_access_2" {
  count = var.deploy_manila * length(openstack_compute_instance_v2.Instance)
  share_id     = local.share_ids[count.index]
  access_type  = "cephx"
  access_to    = "${var.user}"
  access_level = "rw"
  depends_on = [openstack_sharedfilesystem_share_v2.shares]
}

locals {
  access_keys = [ for val in openstack_sharedfilesystem_share_access_v2.share_access : val.access_key]
  access_ids = [ for val in openstack_sharedfilesystem_share_access_v2.share_access : val.id]
  access_locations = [ for val in openstack_sharedfilesystem_share_v2.shares : val.export_locations]
}


resource "null_resource" "attach_manila" {
  count = var.deploy_manila * length(openstack_compute_instance_v2.Instance)
  depends_on = [openstack_sharedfilesystem_share_access_v2.share_access]

  connection {
    type = "ssh"
    user = "${var.user}"
    private_key = file("/home/${var.user}/.ssh/id_rsa")
    host = local.vm_ips[count.index]
  }
  provisioner "remote-exec" {
    inline = [
      "touch /home/${var.user}/manila.sh",
      "touch manila.sh",
      "chmod +x manila.sh",
      "echo #!/bin/bash >> /home/${var.user}/manila.sh",
      "echo sudo mount -t ceph ${local.access_locations[count.index][0].path} -o name=${local.access_names[count.index]},secret=${local.access_keys[count.index]} /mnt/manila >> /home/${var.user}/manila.sh",
      ]
    }
}

##############################################################################
### Deploy volume storage
##############################################################################
resource "openstack_blockstorage_volume_v3" "volumes" {
  count = var.deploy_volume * length(local.my_product)
  name = format("vol-%02d", count.index + 1)
  region = "RegionOne"
  description = "volume for benchmark testing"
  size = var.volume_size
}

locals {
  volume_ids = [ for val in openstack_blockstorage_volume_v3.volumes : val.id]
}

resource "openstack_compute_volume_attach_v2" "vol_attach" {
  count = var.deploy_volume * length(openstack_compute_instance_v2.Instance)
  instance_id = local.vm_ids[count.index]
  volume_id = local.volume_ids[count.index]
}


##############################################################################
### Run ansible playbook
##############################################################################
resource "null_resource" "ansible_playbook" {
  count = length(openstack_compute_instance_v2.Instance)
     provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i staging-openstack.yaml -l ${local.vm_names[count.index]} ${var.playbook_path}"
   }
}











