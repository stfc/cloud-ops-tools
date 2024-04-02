#! /bin/bash
sudo apt install -y python3-openstackclient python3-pip python3-venv
python3 -m venv venv
source venv/bin/activate

pip install ansible
source PATH="/home/$USER/.local/bin:$PATH"
sudo snap install terraform --classic
pip install paramiko

sudo rm -rf /usr/lib/python3/dist-packages/OpenSSL
pip3 install pyopenssl
pip3 install pyopenssl --upgrade

ansible-galaxy collection install -r requirements.yaml
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix