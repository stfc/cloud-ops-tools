#!/usr/bin/env bash
set -euo pipefail


while getopts "p:" arg; do
        case $arg in
                p) path=$OPTARG
        esac
done

if [ -z  "$path" ]; then
        echo no path set
        path=$(pwd)
fi

cd $path
if [ $? -ne 0 ]; then
        mkdir -p $path
fi
cd $path
if [ $? -ne 0 ]; then
        echo Failed to change directory
        exit 1
fi

mkdir benchmarking
cd benchmarking

#######################################################################################################################
# 1000 x 1 KB files
echo -------------------------------------------------------
n=1000
s=0.001
echo $n x $s MB files
echo -------------------------------------------------------


# Sysbench benchmark
output=$(./sysbench.sh -n $n -s $s)
sys_seqw_1=$(echo "$output" | grep -ioP "Sequential write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_seqr_1=$(echo "$output" | grep -ioP "Sequential read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_randw_1=$(echo "$output" | grep -ioP "Random write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_randr_1=$(echo "$output" | grep -ioP "Random read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
echo Seq write: $sys_seqw_1 MB/s
echo Seq read: $sys_seqr_1 MB/s
echo Rand write: $sys_randw_1 MB/s
echo Rand read: $sys_randr_1 MB/s

########################################################################################################################
# 1000 x 1 MB
echo -------------------------------------------------------
n=1000
s=1
echo $n x $s MB files
echo -------------------------------------------------------


# Sysbench benchmark
output=$(./sysbench.sh -n $n -s $s)
sys_seqw_2=$(echo "$output" | grep -ioP "Sequential write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_seqr_2=$(echo "$output" | grep -ioP "Sequential read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_randw_2=$(echo "$output" | grep -ioP "Random write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_randr_2=$(echo "$output" | grep -ioP "Random read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
echo Seq write: $sys_seqw_2 MB/s
echo Seq read: $sys_seqr_2 MB/s
echo Rand write: $sys_randw_2 MB/s
echo Rand read: $sys_randr_2 MB/s

########################################################################################################################
# 10 x 500 Mb files
echo -------------------------------------------------------
n=10
s=500
echo $n x $s MB files
echo -------------------------------------------------------


# Sysbench benchmark
output=$(./sysbench.sh -n $n -s $s)
sys_seqw_3=$(echo "$output" | grep -ioP "Sequential write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_seqr_3=$(echo "$output" | grep -ioP "Sequential read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_randw_3=$(echo "$output" | grep -ioP "Random write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_randr_3=$(echo "$output" | grep -ioP "Random read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
echo Seq write: $sys_seqw_3 MB/s
echo Seq read: $sys_seqr_3 MB/s
echo Rand write: $sys_randw_3 MB/s
echo Rand read: $sys_randr_3 MB/s
