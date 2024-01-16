#!/bin/bash

# Check is Ubuntu 18.04 as this cannot run standard benchmark for 1k files
os=$(lsb_release -a)
if [[ "$os" != *"18.04"* ]]; then
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
fi

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
s=1000
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


server_UUID=$(curl  http://169.254.169.254/openstack/latest/meta_data.json -s  | grep -ioP .{8}-.{4}-.{4}-.{4}-.{12})
vm_info=$(openstack server show $server_UUID --os-cloud openstack)
#hypervisor=$(echo $vm_info | grep -ioP "\w*.nubes.rl.ac.uk" | head -1)
flavor=$(echo $vm_info | grep -ioP "flavor\s\|\s\S*" | cut -c 10-)
image=$(echo $vm_info | grep -ioP "image\s\|\s\S*" | cut -c 9-)
echo $flavor
echo $image

#KB results
curl -H 'Content-Type: application/json' -d '{"metric":"sequential_write","value":"'$sys_seqw_1'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"kb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put

curl -H 'Content-Type: application/json' -d '{"metric":"sequential_read","value":"'$sys_seqr_1'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"kb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put

curl -H 'Content-Type: application/json' -d '{"metric":"random_write","value":"'$sys_randw_1'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"kb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put

curl -H 'Content-Type: application/json' -d '{"metric":"random_read","value":"'$sys_randr_1'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"kb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put


#MB results
curl -H 'Content-Type: application/json' -d '{"metric":"sequential_write","value":"'$sys_seqw_2'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"mb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put

curl -H 'Content-Type: application/json' -d '{"metric":"sequential_read","value":"'$sys_seqr_2'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"mb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put

curl -H 'Content-Type: application/json' -d '{"metric":"random_write","value":"'$sys_randw_2'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"mb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put

curl -H 'Content-Type: application/json' -d '{"metric":"random_read","value":"'$sys_randr_2'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"mb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put


#GB results
curl -H 'Content-Type: application/json' -d '{"metric":"sequential_write","value":"'$sys_seqw_3'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"gb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put

curl -H 'Content-Type: application/json' -d '{"metric":"sequential_read","value":"'$sys_seqr_3'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"gb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put

curl -H 'Content-Type: application/json' -d '{"metric":"random_write","value":"'$sys_randw_3'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"gb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put

curl -H 'Content-Type: application/json' -d '{"metric":"random_read","value":"'$sys_randr_3'","tags":{"flavor":"'$flavor'", "image":"'$image'","test_type":"gb", "storage_type":"local"}}' http://172.16.101.186:4242/api/put



