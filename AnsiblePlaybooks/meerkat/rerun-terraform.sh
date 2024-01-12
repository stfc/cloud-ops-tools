#! /bin/bash

#cd /home/USER/terra-meerkat
terraform init
terraform destroy --auto-approve
terraform plan -out=deploy.tfplan -lock=false
terraform apply "deploy.tfplan"
