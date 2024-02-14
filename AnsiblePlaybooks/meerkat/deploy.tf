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
}

resource "openstack_sharedfilesystem_share_v2" "shares" {
  count = length(openstack_compute_instance_v2.Instance)
  name             = format("share-%02d", count.index + 1)
  description      = "manila terraform share"
  share_proto      = "CEPHFS"
  size             = 15
}

locals {
  share_ids = [ for val in openstack_sharedfilesystem_share_v2.shares : val.id]
}

resource "openstack_sharedfilesystem_share_access_v2" "share_access" {
  count = length(openstack_compute_instance_v2.Instance)
  share_id     = local.share_ids[count.index]
  access_type  = "cephx"
  access_to    = "diz41711"
  access_level = "rw"
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
  instance_id = local.vm_ids[count.index]
  volume_id = local.volume_ids[count.index]

    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i staging-openstack.yaml -l ${local.vm_names[count.index]} /home/diz41711/cloud-ops-tools/AnsiblePlaybooks/meerkat/meerkat.yaml"
    }
}



resource "null_resource" "provisioner" {
  count = length(openstack_compute_instance_v2.Instance)

  connection {
    type = "ssh"
    user = "diz41711"
    private_key = file("/home/diz41711/.ssh/id_rsa")
    host = local.vm_ips[count.index]
  }
  provisioner "remote-exec" {
    inline = [
      "touch /home/diz41711/manila.sh",
#      "echo sudo apt install -y python3-manilaclient >> /home/diz41711/manila.sh",
#      "echo sudo apt install -y ceph-common >> /home/diz41711/manila.sh",
#      "echo sudo mkdir /mnt/manila >> /home/diz41711/manila.sh",
      "touch manila.sh",
      "chmod +x manila.sh",
      "echo #!/bin/bash >> /home/diz41711/manila.sh",
      "echo sudo mount -t ceph ${local.access_locations[count.index][0].path} -o name=diz41711,secret=${local.access_keys[count.index]} /mnt/manila >> /home/diz41711/manila.sh",
#      "echo sudo chown diz41711 /mnt/manila >> /home/diz41711/manila.sh"
      ]
    }
}











