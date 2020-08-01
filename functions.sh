#!/bin/bash

id=$2
dir=$3
homed=$4
prev_time=$5
cur_time=$6

homed_id="$homed/$id"
homed_local="$homed/local/$(basename "$dir")"

check_process () {
    pid=$1
    ps -eo pid,comm | awk -v pid="$pid" '$1 == pid && $2 ~ /.*sync\.sh.*/'
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

case "$1" in

check-lock)
    required_variables=("homed")
    check_variables "$required_variables"

    if [ -f "$homed/local/lock.txt" ]
    then
        read -r lock_info < "$homed/local/lock.txt"

        if [ "$lock_info" -le 4194304 ]
        then
            # pid
            if [ -z $(check_process "$lock_info") ]
            then
                echo 'unlocked'
            else
                echo 'locked'
            fi
        else
            # ping time (epoch)
            minute_ago=$(expr $(date +%s) - 60)
            if [ "$lock_info" -lt "$minute_ago" ]
            then
                echo 'unlocked'
            else
                echo 'locked'
            fi
        fi
    else
        echo 'unlocked'
    fi
    ;;

remove-lock)
    required_variables=("homed")
    check_variables "$required_variables"

    rm "$homed/local/lock.txt"
    ;;

prepare-sync)
    required_variables=("id" "dir" "homed" "homed_id" "homed_local" "prev_time" "cur_time")
    check_variables "$required_variables"

    mkdir -p "$homed_id" "$homed_local" "$dir"

    find "$dir" -printf "%P\t%Ts\t%s\t%y\n" | LC_ALL=C sort > "$homed_id/branch_tmp.txt"

    cp -n "$homed_id/branch_tmp.txt" "$homed_local/base.txt"

    awk -f "$homed/awk/create-branch.awk" -v dir="$dir" -v cur_time="$cur_time" "$homed_local/base.txt" "$homed_id/branch_tmp.txt" > "$homed_id/branch.txt"

    awk -v prev_time="$prev_time" 'BEGIN {FS = "\t"} $5 > prev_time' "$homed_id/branch.txt" > "$homed_id/additions.txt"

    awk -f "$homed/awk/find-deletions.awk" -v cur_time="$cur_time" "$homed_local/base.txt" "$homed_id/branch.txt" > "$homed_id/deletions_tmp.txt"
    awk -f "$homed/awk/merge-deletions.awk" "$homed_id/deletions_tmp.txt" "$homed_local/deletions.txt" > "$homed_id/deletions_tmp1.txt"
    awk -f "$homed/awk/prune-deletions.awk" "$homed_id/branch.txt" "$homed_id/deletions_tmp1.txt" > "$homed_id/pruned_deletions.txt"

    awk -v prev_time="$prev_time" 'BEGIN {FS = "\t"} $5 > prev_time' "$homed_id/pruned_deletions.txt" > "$homed_id/deletions.txt"

    mkdir -p "$homed_id/remote"

    modifications=$(awk -v prev_time="$prev_time" 'BEGIN {FS = "\t"} $5 > prev_time || $2 > prev_time' "$homed_id/branch.txt")
    deletions=$(awk -v prev_time="$prev_time" 'BEGIN {FS = "\t"} $5 > prev_time' "$homed_id/pruned_deletions.txt")

    if [ -z "$modifications" ] && [ -z "$deletions" ]
    then
        echo "unchanged"
        exit 0
    fi
    ;;

# copy additions and deletions

copy-and-delete)
    required_variables=("id" "dir" "homed" "homed_id" "homed_local" "prev_time" "cur_time")
    check_variables "$required_variables"

    awk -f "$homed/awk/merge-deletions.awk" "$homed_id/pruned_deletions.txt" "$homed_id/remote/deletions.txt" > "$homed_id/combined_deletions.txt"
    awk -f "$homed/awk/prune-deletions.awk" "$homed_id/branch.txt" "$homed_id/combined_deletions.txt" > "$homed_id/pruned_deletions.txt"
    awk -f "$homed/awk/prune-deletions.awk" "$homed_id/remote/additions.txt" "$homed_id/pruned_deletions.txt" > "$homed_local/deletions.txt"

    awk -f "$homed/awk/find-additions.awk" "$homed_id/branch.txt" "$homed_id/remote/additions.txt" > "$homed_id/additions_tmp.txt"
    awk -f "$homed/awk/prune-additions.awk" "$homed_local/deletions.txt" "$homed_id/additions_tmp.txt" > "$homed_id/additions.txt"
    awk -f "$homed/awk/pair-additions.awk" "$homed_id/branch.txt" "$homed_id/additions.txt" | LC_ALL=C sort > "$homed_id/paired_additions.txt"
    awk -f "$homed/awk/copy-additions.awk" -v dir="$dir" "$homed_id/paired_additions.txt" "$homed_local/deletions.txt" > "$homed_id/copy_additions.txt"
    cat "$homed_id/copy_additions.txt" | xargs -0 -I {} bash -c '{}'

    awk -f "$homed/awk/validate-deletions.awk" "$homed_id/branch.txt" "$homed_local/deletions.txt" > "$homed_id/deletions.txt"
    awk 'BEGIN {FS = "\t"} {print $1}' "$homed_id/deletions.txt" | xargs -r -I {} rm -rf "$dir/{}"
    ;;

# rsync

cleanup-and-reset)
    required_variables=("id" "dir" "homed" "homed_id" "homed_local" "prev_time" "cur_time")
    check_variables "$required_variables"

    find "$dir" -printf "%P\t%Ts\t%s\t%y\n" | LC_ALL=C sort > "$homed_id/base.txt"
    awk -f "$homed/awk/create-branch.awk" -v dir="$dir" -v cur_time="$cur_time" "$homed_id/branch.txt" "$homed_id/base.txt" > "$homed_local/base.txt"
    rm -r "$homed_id"
    ;;

esac
