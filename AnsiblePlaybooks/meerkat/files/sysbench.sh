#!/bin/bash
echo "Hello Chris"
# Docs: https://imysql.com/wp-content/uploads/2014/10/sysbench-manual.pdf
while getopts "n:s:" arg; do
	case $arg in
		n) n=$OPTARG;;
		s) file_size=$OPTARG;; # in MB
	esac
done

cd $path

####################################################################
# This section handles file sizes < 1 Mb
if [[ "$file_size" == *"."* ]]; then
	file_size="$(echo "scale=3; $file_size * 1000" | bc)"k
fi
# if 2nd char == . then convert to k from M
if [[ "$file_size" == *"k"* ]]; then
	total_size="$(echo "scale=0; $n * ${file_size::-1}" | bc)"k
else
	total_size="$(echo "scale=0; $n * $file_size" | bc)"M
fi

if [[ "$total_size" == *"."* ]]; then
	suffix=${total_size: -1}
	total_size="$(echo "$total_size" | cut -f1 -d".")"$suffix
fi

if [[ ${total_size:0:1} == "." ]]; then
	total_size="0$total_size"
fi
#######################################################################
block_size="16k" # Default block size

echo Total size: $total_size
echo Numebr of files: $n
echo Block size: $block_size


seqw=0
sewr=0
randw=0
randr=0

#sysbench test types: seqwr, seqrd, seqrewr, rndwr, rndrd, rndrw

mkdir sysbench
cd sysbench

# sequential write
echo "Sequential write..."
output=$(sysbench fileio --file-test-mode=seqwr --file-block-size=$block_size --file-num=$n --file-total-size=$total_size run)
seqw=$(echo "$output" | grep -ioP "written, MiB\/s: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
if [ -z "$seqw" ]; then
	seqw=$(echo "$output" | grep -ioP "written, KiB\/s: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
	echo $seqw
	seqw=$(echo "scale=3; $seqw / 1024" | bc)
fi
find . -name "test_file.*" -delete

# sequential read
echo "Sequential read..."
sysbench fileio prepare --file-block-size=$block_size --file-num=$n --file-total-size=$total_size > /dev/null
output=$(sysbench fileio --file-test-mode=seqrd --file-block-size=$block_size --file-num=$n --file-total-size=$total_size run)
seqr=$(echo "$output" | grep -ioP "read, MiB\/s: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
if [ -z "$seqw" ]; then
        seqr=$(echo "$output" | grep -ioP "read, KiB\/s: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
        seqr=$(echo "scale=3; $seqr / 1024" | bc)
fi
find . -name "test_file.*" -delete

# random write
echo "Random write..."
sysbench fileio prepare --file-block-size=$block_size --file-num=$n --file-total-size=$total_size > /dev/null
output=$(sysbench fileio --file-test-mode=rndwr --file-block-size=$block_size --file-num=$n --file-total-size=$total_size run)
randw=$(echo "$output" | grep -ioP "written, MiB\/s: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
if [ -z "$seqw" ]; then
        randw=$(echo "$output" | grep -ioP "written, KiB\/s: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
        randw=$(echo "scale=3; $randw / 1024" | bc)
fi
find . -name "test_file.*" -delete

# random read
echo "Random read..."
sysbench fileio prepare --file-block-size=$block_size --file-num=$n --file-total-size=$total_size > /dev/null
output=$(sysbench fileio --file-block-size=$block_size --file-test-mode=rndrd --file-num=$n --file-total-size=$total_size run)
randr=$(echo "$output" | grep -ioP "read, MiB\/s: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
if [ -z "$seqw" ]; then
        randr=$(echo "$output" | grep -ioP "read, KiB\/s: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
        randr=$(echo "scale=3; $randr / 1024" | bc)
fi
find . -name "test_file.*" -delete


echo "Sequential write:" $seqw "MB/s"
echo "Sequential read:" $seqr "MB/s"
echo "Random write:" $randw "MB/s"
echo "Random read:" $randr "MB/s"

cd ..
rmdir sysbench
