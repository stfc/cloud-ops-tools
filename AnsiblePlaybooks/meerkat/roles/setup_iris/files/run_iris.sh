#! /bin/bash

source env/bin/activate

cd iris-gpubench

iris-gpubench --benchmark_image "stemdl_classification" --interval 10
