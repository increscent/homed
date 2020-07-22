#!/bin/bash

id=$2
dir=$3
homed=$4
prev_time=$5
cur_time=$6

if [ -z "$id" ]
then
    echo "Sync failed: no uuid"
    exit 1
fi

if [ -z "$dir" ]
then
    echo "Sync failed: no dir"
    exit 1
fi

if [ -z "$homed" ]
then
    echo "Sync failed: no homed"
    exit 1
fi

case "$1" in

prepare-sync)
    mkdir -p "$homed/$id" "$homed/local" "$dir"

    find "$dir" -printf "%P\t%Ts\t%s\t%y\n" | LC_ALL=C sort > "$homed/$id/branch_tmp.txt"

    cp -n "$homed/$id/branch_tmp.txt" "$homed/local/base.txt"

    awk -f "$homed/awk/create-branch.awk" -v dir="$dir" -v cur_time="$cur_time" "$homed/local/base.txt" "$homed/$id/branch_tmp.txt" > "$homed/$id/branch.txt"

    awk -v prev_time="$prev_time" 'BEGIN {FS = "\t"} $5 > prev_time' "$homed/$id/branch.txt" > "$homed/$id/additions.txt"

    awk -f "$homed/awk/find-deletions.awk" -v cur_time="$cur_time" "$homed/local/base.txt" "$homed/$id/branch.txt" > "$homed/$id/deletions_tmp.txt"
    awk -f "$homed/awk/merge-deletions.awk" "$homed/$id/deletions_tmp.txt" "$homed/local/deletions.txt" > "$homed/$id/deletions_tmp1.txt"
    awk -f "$homed/awk/prune-deletions.awk" "$homed/$id/branch.txt" "$homed/$id/deletions_tmp1.txt" > "$homed/$id/pruned_deletions.txt"

    awk -v prev_time="$prev_time" 'BEGIN {FS = "\t"} $5 > prev_time' "$homed/$id/pruned_deletions.txt" > "$homed/$id/deletions.txt"
    ;;

# copy additions and deletions

## TODO

create-branch)
    mkdir -p "$homed/$id" "$homed/local" "$dir"

    find "$dir" -printf "%P\t%Ts\t%s\t%y\n" | LC_ALL=C sort > "$homed/$id/branch_tmp.txt"

    cp -n "$homed/$id/branch_tmp.txt" "$homed/local/base.txt"

    awk -f "$homed/awk/create-branch.awk" -v dir="$dir" -v cur_time="$cur_time" "$homed/local/base.txt" "$homed/$id/branch_tmp.txt" > "$homed/$id/branch.txt"
    ;;

# sync branches over

find-deletions)
    awk -f "$homed/awk/find-deletions.awk" "$homed/local/base.txt" "$homed/$id/branch.txt" > "$homed/$id/deletions_tmp.txt"

    cp -n "$homed/$id/deletions_tmp.txt" "$homed/local/deletions.txt"

    awk -f "$homed/awk/merge-deletions.awk" "$homed/$id/deletions_tmp.txt" "$homed/local/deletions.txt" > "$homed/$id/deletions.txt"
    ;;

# sync deletions over

merge-and-prune-deletions)
    awk -f "$homed/awk/merge-deletions.awk" "$homed/$id/deletions.txt" "$homed/$id/remote_deletions.txt" > "$homed/$id/combined_deletions.txt"
    awk -f "$homed/awk/prune-deletions.awk" "$homed/$id/branch.txt" "$homed/$id/combined_deletions.txt" > "$homed/$id/pruned_deletions.txt"
    ;;

# sync pruned deletions over

prune-deletions)
    awk -f "$homed/awk/prune-deletions.awk" "$homed/$id/branch.txt" "$homed/$id/remote_pruned_deletions.txt" > "$homed/local/deletions.txt"
    ;;

find-additions)
    awk -f "$homed/awk/find-additions.awk" "$homed/$id/branch.txt" "$homed/$id/remote_branch.txt" > "$homed/$id/additions_tmp.txt"
    awk -f "$homed/awk/prune-additions.awk" "$homed/local/deletions.txt" "$homed/$id/additions_tmp.txt" > "$homed/$id/additions.txt"
    awk -f "$homed/awk/copy-additions.awk" "$homed/$id/branch.txt" "$homed/$id/additions.txt" > "$homed/$id/copy_additions.txt"
    ;;

copy-additions)
    awk 'BEGIN {FS = "\t"} {print $1}' "$homed/$id/copy_additions.txt" | xargs -r -I {} mkdir -p $(dirname "$dir/{}")
    awk -v dir="$dir" 'BEGIN {FS = "\t"} {printf("cp -a \"%s/%s\" \"%s/%s\"\n", dir, $1, dir, $2)}' "$homed/$id/copy_additions.txt" | xargs -0 -I {} bash -c '{}'
    ;;

delete)
    awk -f "$homed/awk/validate-deletions.awk" "$homed/$id/branch.txt" "$homed/local/deletions.txt" > "$homed/$id/deletions.txt"
    cat "$homed/$id/deletions.txt" | xargs -r -I {} rm -rf "$dir/{}"
    ;;

# rsync

cleanup-and-reset)
    find "$dir" -printf "%P\t%Ts\t%s\t%y\n" | LC_ALL=C sort > "$homed/$id/base.txt"
    awk -f "$homed/awk/create-branch.awk" -v dir="$dir" -v cur_time="$cur_time" "$homed/$id/branch.txt" "$homed/$id/base.txt" > "$homed/local/base.txt"
    rm -r "$homed/$id"
    ;;

esac
