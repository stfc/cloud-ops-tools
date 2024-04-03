#! /bin/bash
set -euo pipefail

help()
{
    echo "Run the Meerkat benchmarking tool"
    echo
    echo "Syntax: scriptTemplate [-h|k]"
    echo "options:"
    echo "h     Print this help."
    echo "k     The keypair used to acess VMs created by Terraform. Required."
    echo "defaults to 'storage'"
    echo
}

if [ $# -eq 0 ]; then
    >&2 help
    exit 1
fi



while getopts hk: flag
do
    case "${flag}" in
        h) help
           exit;;
        k) KEYPAIR=${OPTARG};;
    esac
done

if [ -z ${KEYPAIR+x} ]; then echo "Please provide the name of a key pair to access VMs"; exit; fi


cd ~/cloud-ops-tools/AnsiblePlaybooks/meerkat

terraform init
terraform destroy --auto-approve
terraform plan -out=deploy.tfplan -lock=false -var "keypair_name=$KEYPAIR"
terraform apply "deploy.tfplan"
