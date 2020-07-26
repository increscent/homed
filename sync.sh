#!/bin/bash

source "$1"

id=$(uuidgen)
prev_time=0
cur_time=$(date +%s)

# Make sure variables are set
if [ -z "$id" ] || [ -z "$host" ] || [ -z "$alias" ] || [ -z "$local_dirs" ] || [ -z "$remote_dirs" ] || [ -z "$local_homed" ] || [ -z "$remote_homed" ]
then
    echo "Sync failed: missing variables"
    exit 1
fi

if [ -f "$local_homed/local/prev_time_$alias.txt" ]
then
    read -r prev_time < "$local_homed/local/prev_time_$alias.txt"
fi

echo "prev_time = $prev_time"
echo "cur_time = $cur_time"
echo "date = $(date)"

ssh $host bash -c "uname -a" > /dev/null

if [ $? -ne 0 ]
then
    echo "Sync failed: cannot connect to host"
    exit 1
fi

cd "$local_homed"

for index in ${!local_dirs[*]}
do
    local_dir=${local_dirs[$index]}
    remote_dir=${remote_dirs[$index]}

    echo "Syncing $local_dir (local) to $remote_dir (remote)"

    # Make sure variables are set
    if [ -z "$local_dir" ] || [ -z "$remote_dir" ]
    then
        echo "Sync failed: missing variables"
        exit 1
    fi

    echo "Prepare sync -- local"
    local_prepare_result=$("$local_homed/functions.sh" 'prepare-sync' "$id" "$local_dir" "$local_homed" "$prev_time" "$cur_time")

    if [ "$local_prepare_result" = 'locked' ]
    then
        echo "Sync failed: local locked"
        exit 1
    fi

    echo "Prepare sync -- remote"
    remote_prepare_result=$(ssh $host "\"$remote_homed/functions.sh\" 'prepare-sync' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$prev_time\" \"$cur_time\"")

    if [ "$remote_prepare_result" = 'locked' ]
    then
        echo "Cleanup and reset -- local"
        "$local_homed/functions.sh" 'cleanup-and-reset' "$id" "$local_dir" "$local_homed" "$prev_time" "$cur_time"

        echo "Sync failed: remote locked"
        exit 1
    fi

    if [ "$local_prepare_result" = 'unchanged' ] && [ "$remote_prepare_result" = 'unchanged' ]
    then
        echo "Cleanup and reset -- local"
        "$local_homed/functions.sh" 'cleanup-and-reset' "$id" "$local_dir" "$local_homed" "$prev_time" "$cur_time"

        echo "Cleanup and reset -- remote"
        ssh $host "\"$remote_homed/functions.sh\" 'cleanup-and-reset' \"$id\" \"$remote_dir\" \"$remote_homed\" \"$prev_time\" \"$cur_time\""

        echo "Sync exited: no changes"
        continue
    fi

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

done

echo $cur_time > "$local_homed/local/prev_time_$alias.txt"

if [ -n "$after_command" ]
then
    bash -c "$after_command"
fi

# rsnapshot
