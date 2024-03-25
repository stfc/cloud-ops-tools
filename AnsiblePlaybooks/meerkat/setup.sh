#! /bin/bash
sudo apt install -y python3-openstackclient python3-pip
pip install ansible
source PATH="/home/$USER/.local/bin:$PATH"
sudo snap install terraform --classic
pip install paramiko
sudo rm -rf /usr/lib/python3/dist-packages/OpenSSL
sudo pip3 install pyopenssl
sudo pip3 install pyopenssl --upgrade
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix