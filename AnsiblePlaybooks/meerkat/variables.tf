variable "keypair_name" {
    description = "The keypair to be used."
    default  = "keyless"
}

variable "network_name" {
    description = "The network to be used."
    default  = "Internal"
}

variable "instance_name" {
    description = "The Instance Name to be used."
    default  = "meerkat"
}

variable "image_name" {
    description = "The image name to be used."
    type = list
    default  = ["ubuntu-focal-20.04-nogui"]
}

variable "flavor_name" {
    description = "The flavor name to be used."
    type = list
    default  = ["l3.nano", "l3.tiny"]
}

variable "security_groups" {
    description = "List of security group"
    type = list
    default = ["default"]
}
variable "VM_group" {
    description = "Group to add VMs to for ansible"
    default = "storage"
}
	
