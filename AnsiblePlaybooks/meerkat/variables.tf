##############################################################
### path and user info
##############################################################

variable "user"{
    description = "username for file pathing"
    default = "<username>"
}

variable "playbook_path" {
    description = "Path to playbook to be run"
    default = "/home/<username>/cloud-ops-tools/AnsiblePlaybooks/meerkat/meerkat.yaml"
}

##############################################################
### VM details
##############################################################

variable "flavor_name" {
    description = "List of flavor names to be used"
    type = list
    default  = ["l3.nano", "l3.micro"]
}

variable "image_name" {
    description = "List of image names to be used"
    type = list
    default  = ["ubuntu-focal-20.04-nogui"]
}

variable "keypair_name" {
    description = "The keypair to be used"
    default  = "keyless"
}

variable "network_name" {
    description = "The network to be used."
    default  = "Internal"
}

variable "instance_name" {
    description = "Instance name prefix"
    default  = "meerkat"
}

variable "security_groups" {
    description = "List of security groups"
    type = list
    default = ["default"]
}
variable "VM_group" {
    description = "Group to add VMs to for ansible"
    default = "storage"
}

variable "tags" {
    description = "Tags to determine which benchmark to run"
    default = "storage"
}

##############################################################
### Volume details
##############################################################

variable "deploy_volume" {
    description = "Whether to deploy volumes, 1 for deploy, 0 for don't deploy"
    default = 1 
}

variable "volume_size" {
    description = "The size of the volume to commission"
    default = 15
}
##############################################################
### Manila details
##############################################################

variable "deploy_manila" {
    description = "Whether to deploy manila share, 1 for deploy, 0 for don't deploy"
    default = 1 
}

variable "share_size" {
    description = "The size of the manila shares to commission"
    default = 15
}