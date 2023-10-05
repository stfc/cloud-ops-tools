#!/bin/bash

#set  -x
set -u
#set -e
##############################################################################################################
# Setting up variables
ceph_user="rfi_speedtest"
remote_mount_dir="/rfi/tmp/speedtest"
mons="deneb-mon1.nubes.rl.ac.uk, deneb-mon2.nubes.rl.ac.uk, deneb-mon3.nubes.rl.ac.uk"
meas="rfi_speed"

mons_no_whitespace=$(echo $mons | tr -d ' ')
secretfile="/etc/ceph/ceph.client.${ceph_user}.keyring"
ceph_key=$(cat $secretfile | grep "key =" | awk '{print $3}')
local_mount_dir="/tmp/cephfs-mnt-test-$(uuidgen)"
test_dir="test-$(uuidgen)"

##############################################################################################################
# testing if able to create directory for mounting in
timeout -k 10 20 mkdir $local_mount_dir >/dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then
 timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
 echo "ERR: can't create local dir for test mount"
 exit 2
fi

##############################################################################################################
# mount storage (mons) (and time it)
mount_start=$(date +%s%N)
timeout -k 10 20 mount -t ceph $mons_no_whitespace:$remote_mount_dir $local_mount_dir -o name=$ceph_user,secret=$ceph_key >/dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then
 # If mount failed
 timeout -k 10 20 umount $local_mount_dir >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
 echo "ERR: mounting CephFS failed"
 exit 2
else
 # Print mounting time
 mount_dur=$(( $(date +%s%N) - $mount_start ))
 echo $mount_dur | awk -v meas=$meas -v op="mount" '{print meas ",op=" op " duration=" $1}'
fi

##############################################################################################################
# cretae directory in mount storage (and time it)
mkdir_start=$(date +%s%N)
timeout -k 10 20 mkdir $local_mount_dir/$test_dir >/dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then
 # If mount failed
 timeout -k 10 20 rmdir $local_mount_dir/$test_dir >/dev/null 2>&1
 timeout -k 10 20 umount $local_mount_dir >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
 echo "ERR: creating directory on CephFS mount failed"
 exit 2
else
 # Print creating time
 mkdir_dur=$(( $(date +%s%N) - $mkdir_start ))
 echo $mkdir_dur | awk -v meas=$meas -v op="mkdir" '{print meas ",op=" op " duration=" $1}'
fi

##############################################################################################################
# Test if able to write files using dd
timeout -k 40 50 dd if=/dev/zero of=/tmp/test.file bs=4M count=256 >/dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then
 echo "ERR: creating test file"
 timeout -k 10 20 rm -f /tmp/test.file >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir/$test_dir >/dev/null 2>&1
 timeout -k 10 20 umount $local_mount_dir >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
 exit 2
fi

##############################################################################################################
# Copying file to test mount (and timing it)
write_start=$(date +%s%N)
timeout -k 60 65 cp /tmp/test.file $local_mount_dir/$test_dir/${test_dir}.file >/dev/null 2>&1
rc=$?
#echo timeout -k 10 20 dd if=/tmp/test.file of=$local_mount_dir/$test_dir/${test_dir}.file oflag=direct

if [ $rc -ne 0 ]; then
 echo "ERR: writing test file to CephFS failed"
 timeout -k 10 20 rm -f $local_mount_dir/$test_dir/${test_dir}.file >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir/$test_dir >/dev/null 2>&1
 timeout -k 10 20 umount $local_mount_dir >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
 exit 2
else
 #sync # finish write
 sync; echo 3 > /proc/sys/vm/drop_caches
 write_dur=$(( $(date +%s%N) - $write_start ))
 echo $write_dur | awk -v meas=$meas -v op="write" '{print meas ",op=" op " duration=" $1 ",rate=" 1024/($1/10^9)}'
fi

sync; echo 3 > /proc/sys/vm/drop_caches

##############################################################################################################
# Write to test mount using dd (and time it)
read_start=$(date +%s%N)
timeout -k 60 70 dd if=$local_mount_dir/$test_dir/${test_dir}.file of=/dev/null >/dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then
 timeout -k 10 20 rm -f $local_mount_dir/$test_dir/${test_dir}.file >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir/$test_dir >/dev/null 2>&1
 timeout -k 10 20 umount $local_mount_dir >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
 echo "ERR: reading test file on CephFS mount failed"
 exit 2
else
 read_dur=$(( $(date +%s%N) - $read_start ))
 echo $read_dur | awk -v meas=$meas -v op="read" '{print meas ",op=" op " duration=" $1 ",rate=" 1024/($1/10^9)}'
fi

##############################################################################################################
# Removing test files from mounted directory
rm_start=$(date +%s%N)
timeout -k 10 20 rm -f $local_mount_dir/$test_dir/${test_dir}.file >/dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then
 timeout -k 10 20 rm -f $local_mount_dir/$test_dir/${test_dir}.file >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir/$test_dir >/dev/null 2>&1
 timeout -k 10 20 umount $local_mount_dir >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
 echo "ERR: removing test file on CephFS mount failed"
 exit 2
else
 rm_dur=$(( $(date +%s%N) - $rm_start ))
 echo $rm_dur | awk -v meas=$meas -v op="rm" '{print meas ",op=" op " duration=" $1}'
fi

##############################################################################################################
# Removing directory on mount
rmdir_start=$(date +%s%N)

timeout -k 10 20 rmdir $local_mount_dir/$test_dir >/dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then
 timeout -k 10 20 rmdir $local_mount_dir/$test_dir >/dev/null 2>&1
 timeout -k 10 20 umount $local_mount_dir >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
 echo "ERR: removing directory on CephFS mount failed"
 exit 2
else
 rmdir_dur=$(( $(date +%s%N) - $rmdir_start ))
 echo $rmdir_dur | awk -v meas=$meas -v op="rmdir" '{print meas ",op=" op " duration=" $1}'
fi

##############################################################################################################
# Unmounting and removing directiory
unmount_start=$(date +%s%N)

timeout -k 10 20 umount $local_mount_dir >/dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then
 timeout -k 10 20 umount $local_mount_dir >/dev/null 2>&1
 timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
 echo "ERR: unmounting CephFS failed"
 exit 2
else
 unmount_dur=$(( $(date +%s%N) - $unmount_start ))
 echo $unmount_dur | awk -v meas=$meas -v op="unmount" '{print meas ",op=" op " duration=" $1}'
fi

timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then
 timeout -k 10 20 rmdir $local_mount_dir >/dev/null 2>&1
 echo "WARN: removing local test directory failed"
 exit 1
fi

exit 0
##############################################################################################################
