#!/bin/bash



########################################################################################################################
# 1000 x 1 KB files
echo -------------------------------------------------------
n=1000
s=0.001
echo $n x $s MB files
echo -------------------------------------------------------

# Python benchmark
output=$(python3 speed_test.py -n $n -s $s)
pkw=$(echo "$output" | grep -ioP "Write speed: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
pkr=$(echo "$output" | grep -ioP "Read speed: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
echo Write: $pkw MB/s
echo Read: $pkr MB/s

# Sysbench benchmark
output=$(./sysbench.sh -n $n -s $s)
sys_g_seqw=$(echo "$output" | grep -ioP "Sequential write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_g_seqr=$(echo "$output" | grep -ioP "Sequential read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_g_randw=$(echo "$output" | grep -ioP "Random write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_g_randr=$(echo "$output" | grep -ioP "Random read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
echo Seq write: $sys_g_seqw MB/s
echo Seq read: $sys_g_seqr MB/s
echo Rand write: $sys_g_randw MB/s
echo Rand read: $sys_g_randr MB/s

########################################################################################################################
# 1000 x 1 MB
echo -------------------------------------------------------
n=1000
s=1
echo $n x $s MB files
echo -------------------------------------------------------

# Python benchmark
output=$(python3 speed_test.py -n $n -s $s)
pmw=$(echo "$output" | grep -ioP "Write speed: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
pmr=$(echo "$output" | grep -ioP "Read speed: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
echo Write: $pmw MB/s
echo Read: $pmr MB/s

# Sysbench benchmark
output=$(./sysbench.sh -n $n -s $s)
sys_m_seqw=$(echo "$output" | grep -ioP "Sequential write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_m_seqr=$(echo "$output" | grep -ioP "Sequential read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_m_randw=$(echo "$output" | grep -ioP "Random write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_m_randr=$(echo "$output" | grep -ioP "Random read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
echo Seq write: $sys_m_seqw MB/s
echo Seq read: $sys_m_seqr MB/s
echo Rand write: $sys_m_randw MB/s
echo Rand read: $sys_m_randr MB/s

########################################################################################################################
# 10 x 1 GB files
echo -------------------------------------------------------
n=10
s=1000
echo $n x $s MB files
echo -------------------------------------------------------

# Python benchmark
output=$(python3 speed_test.py -n $n -s $s)
pgw=$(echo "$output" | grep -ioP "Write speed: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
pgr=$(echo "$output" | grep -ioP "Read speed: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
echo Write: $pgw MB/s
echo Read: $pgr MB/s

# Sysbench benchmark
output=$(./sysbench.sh -n $n -s $s)
sys_g_seqw=$(echo "$output" | grep -ioP "Sequential write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_g_seqr=$(echo "$output" | grep -ioP "Sequential read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_g_randw=$(echo "$output" | grep -ioP "Random write: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
sys_g_randr=$(echo "$output" | grep -ioP "Random read: +(?)\d+(?:\.\d+)?" | grep -oP "\d+(?:\.\d+)?")
echo Seq write: $sys_g_seqw MB/s
echo Seq read: $sys_g_seqr MB/s
echo Rand write: $sys_g_randw MB/s
echo Rand read: $sys_g_randr MB/s
