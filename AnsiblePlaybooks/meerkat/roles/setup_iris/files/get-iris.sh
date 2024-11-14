#!/bin/bash

# Install Drivers

sudo ubuntu-drivers autoinstall

# Set up benchmark enviroment

mkdir iris_bench
cd iris_bench

git clone https://github.com/bryceshirley/iris-bench.git

cd iris-gpubench

sudo groupadd docker
sudo username -aG docker $user
newgrp docker

python3 -m venv env

source env/bin/activate

pip install wheel

pip install .

./dockerfiles/build_images.sh

iris-gpubench --benchmark_image "synthetic_regression" --export_to_meerkat
