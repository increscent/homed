#!/bin/bash

host=home
id=$(uuidgen)
local_dir=/home/robert/Documents
remote_dir=/home/robert/Documents
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

echo "Find deletions -- local"
"$local_homed/functions.sh" 'find-deletions' "$id" "$local_dir" "$local_homed"

echo "Find deletions -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'find-deletions' \"$id\" \"$remote_dir\" \"$remote_homed\""

scp $host:"$remote_homed/$id/deletions.txt" "$local_homed/$id/remote_deletions.txt"
scp "$local_homed/$id/deletions.txt" $host:"$remote_homed/$id/remote_deletions.txt"

echo "Merge and prune deletions -- local"
"$local_homed/functions.sh" 'merge-and-prune-deletions' "$id" "$local_dir" "$local_homed"

echo "Merge and prune deletions -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'merge-and-prune-deletions' \"$id\" \"$remote_dir\" \"$remote_homed\""

scp $host:"$remote_homed/$id/pruned_deletions.txt" "$local_homed/$id/remote_pruned_deletions.txt"
scp "$local_homed/$id/pruned_deletions.txt" $host:"$remote_homed/$id/remote_pruned_deletions.txt"

echo "Prune deletions -- local"
"$local_homed/functions.sh" 'prune-deletions' "$id" "$local_dir" "$local_homed"

echo "Prune deletions -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'prune-deletions' \"$id\" \"$remote_dir\" \"$remote_homed\""

# TODO move files to trash instead of deleting them
echo "Delete -- local"
"$local_homed/functions.sh" 'delete' "$id" "$local_dir" "$local_homed"

echo "Delete -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'delete' \"$id\" \"$remote_dir\" \"$remote_homed\""

echo "rsync -- local -> remote"
rsync -qavz "$local_dir/" $host:"$remote_dir"

echo "rsync -- remote -> local"
rsync -qavz $host:"$remote_dir/" "$local_dir"

echo "Cleanup and reset -- local"
"$local_homed/functions.sh" 'cleanup-and-reset' "$id" "$local_dir" "$local_homed"

echo "Cleanup and reset -- remote"
ssh $host "\"$remote_homed/functions.sh\" 'cleanup-and-reset' \"$id\" \"$remote_dir\" \"$remote_homed\""

# rsnapshot
