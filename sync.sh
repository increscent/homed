#!/bin/bash

# things to add:
#   - lock (one sync at a time)
#   - abort if unchanged
#   - mv file if source is only copied once and will be deleted

host=home
id=$(uuidgen)
prev_time=0
cur_time=$(date +%s)
local_dir=/home/robert/tmp
remote_dir=/home/robert/tmp
local_homed=/home/robert/homed
remote_homed=/home/robert/homed

# homed/local/deletions.txt         saved deletions for previous/future run
# homed/$id/deletions.txt           working deletions for current run
# homed/$id/pruned_deletions.txt    working pruned deletions for current run

cd "$local_homed"

if [ -f "$local_homed/local/prev_time.txt" ]
then
    read -r prev_time < "$local_homed/local/prev_time.txt"
fi

echo "prev_time = $prev_time"

if [ -z "$id" ]
then
    echo "Sync failed: no uuid"
    exit 1
fi

ssh $host bash -c "uname -a" > /dev/null

if [ $? -ne 0 ]
then
    echo "Sync failed: cannot connect to host"
    exit 1
fi

echo "Prepare sync -- local"
"$local_homed/functions.sh" 'prepare-sync' "$id" "$local_dir" "$local_homed" "$prev_time" "$cur_time"

echo "Prepare sync -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'prepare-sync' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$prev_time\" \"$cur_time\""

scp $host:"$remote_homed/$id/additions.txt" "$local_homed/$id/remote/additions.txt"
scp $host:"$remote_homed/$id/deletions.txt" "$local_homed/$id/remote/deletions.txt"
scp "$local_homed/$id/additions.txt" $host:"$remote_homed/$id/remote/additions.txt"
scp "$local_homed/$id/deletions.txt" $host:"$remote_homed/$id/remote/deletions.txt"

echo "Copy and delete -- local"
"$local_homed/functions.sh" 'copy-and-delete' "$id" "$local_dir" "$local_homed" "$prev_time" "$cur_time"

echo "Copy and delete -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'copy-and-delete' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$prev_time\" \"$cur_time\""

echo "rsync -- local -> remote"
rsync -uavz "$local_dir/" $host:"$remote_dir"

echo "rsync -- remote -> local"
rsync -uavz $host:"$remote_dir/" "$local_dir"

echo "Cleanup and reset -- local"
"$local_homed/functions.sh" 'cleanup-and-reset' "$id" "$local_dir" "$local_homed" "$prev_time" "$cur_time"

echo "Cleanup and reset -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'cleanup-and-reset' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$prev_time\" \"$cur_time\""

echo $cur_time > "$local_homed/local/prev_time.txt"

# rsnapshot
