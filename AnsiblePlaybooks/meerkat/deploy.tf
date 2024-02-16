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


resource "openstack_sharedfilesystem_share_v2" "shares" {
#  count = length(openstack_compute_instance_v2.Instance)
  count = length(local.my_product)
  name             = format("share-%02d", count.index + 1)
  description      = "manila terraform share"
  share_proto      = "CEPHFS"
  size             = 15
}

resource "openstack_compute_instance_v2" "Instance" {
  depends_on = [openstack_sharedfilesystem_share_v2.shares]
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
  share_ids = [ for val in openstack_sharedfilesystem_share_v2.shares : val.id]

}

resource "random_password" "access_names" {
  count = length(openstack_compute_instance_v2.Instance)
  length = 16
  special = false
}

locals {
  access_names = [for val in random_password.access_names : val.result]
}

resource "openstack_sharedfilesystem_share_access_v2" "share_access" {
  count = length(openstack_compute_instance_v2.Instance)
  share_id     = local.share_ids[count.index]
  access_type  = "cephx"
  access_to = local.access_names[count.index]
  access_level = "rw"
  depends_on = [openstack_sharedfilesystem_share_v2.shares]
}

resource "openstack_sharedfilesystem_share_access_v2" "share_access_2" {
  count = length(openstack_compute_instance_v2.Instance)
  share_id     = local.share_ids[count.index]
  access_type  = "cephx"
  access_to    = "diz41711"
  access_level = "rw"
  depends_on = [openstack_sharedfilesystem_share_v2.shares]
}


locals {
  access_keys = [ for val in openstack_sharedfilesystem_share_access_v2.share_access : val.access_key]
  access_ids = [ for val in openstack_sharedfilesystem_share_access_v2.share_access : val.id]
  access_locations = [ for val in openstack_sharedfilesystem_share_v2.shares : val.export_locations]

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
  vm_ips = [for val in openstack_compute_instance_v2.Instance : val.access_ip_v4]
}

resource "openstack_compute_volume_attach_v2" "vol_attach" {
  count = length(openstack_compute_instance_v2.Instance)
  depends_on = [openstack_blockstorage_volume_v3.volumes]
  instance_id = local.vm_ids[count.index]
  volume_id = local.volume_ids[count.index]

    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i staging-openstack.yaml -l ${local.vm_names[count.index]} /home/diz41711/cloud-ops-tools/AnsiblePlaybooks/meerkat/meerkat.yaml"
    }
}

resource "null_resource" "provisioner" {
  count = length(openstack_compute_instance_v2.Instance)
  depends_on = [openstack_sharedfilesystem_share_access_v2.share_access]

  connection {
    type = "ssh"
    user = "diz41711"
    private_key = file("/home/diz41711/.ssh/id_rsa")
    host = local.vm_ips[count.index]
  }
  provisioner "remote-exec" {
    inline = [
      "touch /home/diz41711/manila.sh",
      "touch manila.sh",
      "chmod +x manila.sh",
      "echo #!/bin/bash >> /home/diz41711/manila.sh",
      "echo sudo mount -t ceph ${local.access_locations[count.index][0].path} -o name=${local.access_names[count.index]},secret=${local.access_keys[count.index]} /mnt/manila >> /home/diz41711/manila.sh",
      ]
    }
}











