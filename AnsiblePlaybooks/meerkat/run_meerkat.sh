#! /bin/bash
set -euo pipefail

help()
{
    echo "Run the Meerkat benchmarking tool"
    echo
    echo "Syntax: scriptTemplate [-h|k|t]"
    echo "options:"
    echo "h     Print this help."
    echo "k     The keypair used to acess VMs created by Terraform. Required."
    echo "t     Tags to determine which benchmark to run. Given as a comma separated list, e.g. 'storage,cpu'."
    echo "defaults to 'storage'"
    echo
}

if [ $# -eq 0 ]; then
    >&2 help
    exit 1
fi


while getopts hk:t: flag
do
    case "${flag}" in
        h) help
           exit;;
        k) KEYPAIR=${OPTARG};;
        t) TAGS=${OPTARG};;
    esac
done

if [ -z ${KEYPAIR+x} ]; then echo "Please provide the name of a key pair to access VMs"; exit; fi

if [ -z ${TAGS+x} ]; then echo "No tags provided, using default tags: 'storage'"; TAGS=storage; fi

terraform init
terraform destroy --auto-approve
terraform plan -out=deploy.tfplan -lock=false -var "keypair_name=$KEYPAIR" -var "tags=$TAGS"
terraform apply "deploy.tfplan"
