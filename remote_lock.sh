#!/bin/bash

sync_pid=$1
remote_host=$2
local_lock_file=$3
remote_lock_file=$4

check_process () {
    pid=$1
    ps -eo pid,comm | awk -v pid="$pid" '$1 == pid && $2 ~ /.*sync\.sh.*/'
}

while [ -n $(check_process "$sync_pid") ] && [ -f "$local_lock_file" ]
do
    ssh $host "echo $(date +%s) > \"$remote_lock_file\""
    sleep 30
done

echo "Done locking remote"
