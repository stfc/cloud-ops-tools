#!/bin/bash
# Docs: https://fio.readthedocs.io/en/latest/fio_doc.html
while getopts "n:s:b:" arg; do
        case $arg in
                n) n=$OPTARG;;
                s) fs=$OPTARG;;
                b) block_size=$OPTARG;;
        esac
done

# Setting variables
unbuffed="0" # if output is unbuffered
fio_filename="fio.fio" # file fio writes data to
file_size=$(( $fs * 1024 * 1024 ))
total_size=$(( n * $file_size ))

if [ -z "$block_size" ]; then
        block_size="16384" # Default block size
fi


# Sequential write
t1=$(date +%s%N | cut -b1-13)
for i in $(seq 1 $n); do
        output=$(fio --ioengine=libaio --direct=$unbuffed --gtod_reduce=1 --name=test --filename=$fio_filename --bs=$block_size --iodepth=64  --filesize=$file_size --readwrite=write --bwavgtime=5)
        #rm $fio_filename
done
t2=$(date +%s%N | cut -b1-13)
#seqw=$(echo "$output" | grep -oP "WRITE: bw=\d+(?:\.\d+)?+MiB\/s" | grep -oP "\d+(?:\.\d+)?")

# Sequential read
for i in $(seq 1 $n); do
        output=$(fio --ioengine=libaio --direct=$unbuffed --gtod_reduce=1 --name=test --filename=$fio_filename --bs=$block_size --iodepth=64  --filesize=$file_size --readwrite=read)
        #rm $fio_filename
done
t3=$(date +%s%N | cut -b1-13)
#seqr=$(echo "$output" | grep -oP "READ: bw=\d+(?:\.\d+)?+MiB\/s" | grep -oP "\d+(?:\.\d+)?")

# Random write
for i in $(seq 1 $n); do
        output=$(fio --ioengine=libaio --direct=$unbuffed --gtod_reduce=1 --name=test --filename=$fio_filename --bs=$block_size --iodepth=64  --filesize=$file_size --readwrite=randwrite)
        #rm $fio_filename
done
t4=$(date +%s%N | cut -b1-13)
#randw=$(echo "$output" | grep -oP "WRITE: bw=\d+(?:\.\d+)?+MiB\/s" | grep -oP "\d+(?:\.\d+)?")

# Random read
for i in $(seq 1 $n); do
        output=$(fio --ioengine=libaio --direct=$unbuffed --gtod_reduce=1 --name=test --filename=$fio_filename --bs=$block_size --iodepth=64 --filesize=$file_size --readwrite=randread)
        #rm $fio_filename
done
t5=$(date +%s%N | cut -b1-13)
#randr=$(echo "$output" | grep -oP "READ: bw=\d+(?:\.\d+)?+MiB\/s" | grep -oP "\d+(?:\.\d+)?")

seqw=$(((($t2 - $t1 | bc) / ($n * $fs | bc)) | bc))
seqr=$(((($t3 - $t2 | bc) / ($n * $fs | bc)) | bc))
randw=$(((($t4 - $t3 | bc) / ($n * $fs | bc)) | bc))
randr=$(((($t5 - $t4 | bc) / ($n * $fs | bc)) | bc))

echo "Sequential write:" $seqw "MB/s"
echo "Sequential read:" $seqr "MB/s"
echo "Random write:" $randw "MB/s"
echo "Random read:" $randr "MB/s"
