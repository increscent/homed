#!/bin/bash

# available global variables: host, alias, local_dirs, remote_dirs, local_homed, remote_homed

call_local_function () {
    function_name="$1"
    echo "Calling local function: $function_name"
    local_result=$("$local_homed/functions.sh" "$function_name" "$id" "$local_dir" "$local_homed" "$prev_time" "$cur_time")
    if [ $? -ne 0 ]
    then
        echo "Sync failed: local script failed"
        exit 1
    fi
}

call_remote_function () {
    function_name="$1"
    echo "Calling remote function: $function_name"
    remote_result=$(ssh $host "\"$remote_homed/functions.sh\" \"$function_name\" \"$id\" \"$remote_dir\" \"$remote_homed\" \"$prev_time\" \"$cur_time\"")
    if [ $? -ne 0 ]
    then
        echo "Sync failed: remote script failed"
        exit 1
    fi
}

check_variables () {
    variables="$1"
    for var in "${variables[@]}"
    do
        if [ -z "${!var}" ]
        then
            echo "Sync failed: missing variable ($var)"
            exit 1
        fi
    done
}

end_lock_remote () {
    if [ -n "$lock_remote_pid" ]
    then
        kill "$lock_remote_pid"
    fi
}

get_prev_time () {
    if [ -f "$local_homed/local/prev_time_$alias.txt" ]
    then
        read -r prev_time < "$local_homed/local/prev_time_$alias.txt"
    else
        prev_time=0
    fi

    echo $prev_time
}

lock_local () {
    echo $$ > "$local_homed/local/lock.txt"
}

lock_remote () {
    ssh $host "echo $(date +%s) > \"$remote_homed/local/lock.txt\""
    ./remote_lock.sh "&&" "$host" "$local_homed/local/lock.txt" "$remote_homed/local/lock.txt" &
    lock_remote_pid=$!
}

run_user_command () {
    command="$1"
    if [ -n "$command" ]
    then
        echo "Running user command: $command"
        bash -c "$command"
        echo "Finished user command: $command"
    fi
}

save_prev_time () {
    echo $cur_time > "$local_homed/local/prev_time_$alias.txt"
}

test_connection () {
    ssh $host "echo test > /dev/null"

    if [ $? -ne 0 ]
    then
        echo "Sync failed: cannot connect to host"
        exit 1
    fi
}
