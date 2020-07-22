#!/bin/bash

# things to add:
#   - lock (one sync at a time)
#   - abort if unchanged

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

echo "Create branch -- local"
"$local_homed/functions.sh" 'create-branch' "$id" "$local_dir" "$local_homed" "$prev_time" "$cur_time"

echo "Create branch -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'create-branch' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$cur_time\""

scp $host:"$remote_homed/$id/branch.txt" "$local_homed/$id/remote_branch.txt"
scp "$local_homed/$id/branch.txt" $host:"$remote_homed/$id/remote_branch.txt"

echo "Find deletions -- local"
"$local_homed/functions.sh" 'find-deletions' "$id" "$local_dir" "$local_homed" "$cur_time"

echo "Find deletions -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'find-deletions' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$cur_time\""

scp $host:"$remote_homed/$id/deletions.txt" "$local_homed/$id/remote_deletions.txt"
scp "$local_homed/$id/deletions.txt" $host:"$remote_homed/$id/remote_deletions.txt"

echo "Merge and prune deletions -- local"
"$local_homed/functions.sh" 'merge-and-prune-deletions' "$id" "$local_dir" "$local_homed" "$cur_time"

echo "Merge and prune deletions -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'merge-and-prune-deletions' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$cur_time\""

scp $host:"$remote_homed/$id/pruned_deletions.txt" "$local_homed/$id/remote_pruned_deletions.txt"
scp "$local_homed/$id/pruned_deletions.txt" $host:"$remote_homed/$id/remote_pruned_deletions.txt"

echo "Prune deletions -- local"
"$local_homed/functions.sh" 'prune-deletions' "$id" "$local_dir" "$local_homed" "$cur_time"

echo "Prune deletions -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'prune-deletions' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$cur_time\""

echo "Find additions -- local"
"$local_homed/functions.sh" 'find-additions' "$id" "$local_dir" "$local_homed" "$cur_time"

echo "Find additions -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'find-additions' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$cur_time\""

echo "Copy additions -- local"
"$local_homed/functions.sh" 'copy-additions' "$id" "$local_dir" "$local_homed" "$cur_time"

echo "Copy additions -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'copy-additions' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$cur_time\""

# TODO move files to trash instead of deleting them
echo "Delete -- local"
"$local_homed/functions.sh" 'delete' "$id" "$local_dir" "$local_homed" "$cur_time"

echo "Delete -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'delete' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$cur_time\""

echo "rsync -- local -> remote"
rsync -quavz "$local_dir/" $host:"$remote_dir"

echo "rsync -- remote -> local"
rsync -quavz $host:"$remote_dir/" "$local_dir"

echo "Cleanup and reset -- local"
"$local_homed/functions.sh" 'cleanup-and-reset' "$id" "$local_dir" "$local_homed" "$cur_time"

echo "Cleanup and reset -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'cleanup-and-reset' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$cur_time\""

# rsnapshot
