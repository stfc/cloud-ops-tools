#! /bin/bash

#cd /home/USER/terra-meerkat
cd /home/diz41711/cloud-ops-tools/AnsiblePlaybooks/meerkat
terraform init
terraform destroy --auto-approve
terraform plan -out=deploy.tfplan -lock=false
terraform apply "deploy.tfplan"
