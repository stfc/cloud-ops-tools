#!/bin/bash

# Check if VM has GPU

if lspci | grep -i 'vga\|3d\|display' > /dev/null; then

  # Install Drivers

  sudo ubuntu-drivers autoinstall

  # Set up benchmark enviroment

  git clone https://github.com/Chris-green-stfc/iris-bench.git

  # Expected run location: /home/<user>

  cd iris-gpubench

  sudo groupadd docker
  sudo username -aG docker $user
  newgrp docker

  python3 -m venv env

  source env/bin/activate

  pip install wheel

  pip install .

  ./dockerfiles/build_images.sh

  ./setup_vm_docker.sh

else
  echo "GPU benchmarking skipped: No GPU detected"
fi
