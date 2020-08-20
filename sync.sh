#!/bin/bash

config="$1"
source "$config"
source "$local_homed/sync_helper.sh"

id=$(uuidgen)

required_variables=("id" "host" "alias" "local_dirs" "remote_dirs" "local_homed" "remote_homed")
optional_variables=("before_command" "after_command")
check_variables "$required_variables"

cd "$local_homed"

prev_time=$(get_prev_time)
cur_time=$(date +%s)

echo ""
echo "New sync: $alias"
echo "--------------------------------------------------------------"
echo "date = $(date)"
echo "prev_time = $prev_time"
echo "cur_time = $cur_time"

run_user_command "$before_command"

call_local_function 'check-lock'

if [ "$local_result" = 'locked' ]
then
    echo 'Sync failed: locked locally'
    exit 1
else
    lock_local
fi

test_connection

call_remote_function 'check-lock'

if [ "$remote_result" = 'locked' ]
then
    echo 'Sync failed: locked remotely'
    call_local_function 'remove-lock'
    exit 1
else
    lock_remote
fi

for index in ${!local_dirs[*]}
do
    local_dir=${local_dirs[$index]}
    remote_dir=${remote_dirs[$index]}

    echo "Syncing $local_dir (local) to $remote_dir (remote)"

    dir_variables=("local_dir" "remote_dir")
    check_variables "$dir_variables"

    call_local_function 'prepare-sync'
    call_remote_function 'prepare-sync'

    if [ "$local_result" = 'unchanged' ] && [ "$remote_result" = 'unchanged' ]
    then
        call_local_function 'cleanup'
        call_remote_function 'cleanup'
        echo "Sync exited: no changes"
        continue
    fi

    scp $host:"$remote_homed/$id/additions.txt" "$local_homed/$id/remote/additions.txt"
    scp $host:"$remote_homed/$id/deletions.txt" "$local_homed/$id/remote/deletions.txt"
    scp "$local_homed/$id/additions.txt" $host:"$remote_homed/$id/remote/additions.txt"
    scp "$local_homed/$id/deletions.txt" $host:"$remote_homed/$id/remote/deletions.txt"

    call_local_function 'copy-and-delete'
    call_remote_function 'copy-and-delete'

    echo "rsync -- local -> remote"
    rsync -uprtDvz "$local_dir/" $host:"$remote_dir"
    echo "rsync -- remote -> local"
    rsync -uprtDvz $host:"$remote_dir/" "$local_dir"

    call_local_function 'cleanup-and-reset'
    call_remote_function 'cleanup-and-reset'
done

call_local_function 'remove-lock'
end_lock_remote
call_remote_function 'remove-lock'

save_prev_time

run_user_command "$after_command"

# rsnapshot
