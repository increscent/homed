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

    mkdir -p "$homed/$id/remote"
    ;;

# copy additions and deletions

copy-and-delete)
    awk -f "$homed/awk/merge-deletions.awk" "$homed/$id/deletions.txt" "$homed/$id/remote/deletions.txt" > "$homed/$id/combined_deletions.txt"
    awk -f "$homed/awk/prune-deletions.awk" "$homed/$id/branch.txt" "$homed/$id/combined_deletions.txt" > "$homed/$id/pruned_deletions.txt"
    awk -f "$homed/awk/prune-deletions.awk" "$homed/$id/remote/additions.txt" "$homed/$id/pruned_deletions.txt" > "$homed/local/deletions.txt"

    awk -f "$homed/awk/find-additions.awk" "$homed/$id/branch.txt" "$homed/$id/remote/additions.txt" > "$homed/$id/additions_tmp.txt"
    awk -f "$homed/awk/prune-additions.awk" "$homed/local/deletions.txt" "$homed/$id/additions_tmp.txt" > "$homed/$id/additions.txt"
    awk -f "$homed/awk/copy-additions.awk" -v dir="$dir" "$homed/$id/branch.txt" "$homed/$id/additions.txt" > "$homed/$id/copy_additions.txt"
    cat "$homed/$id/copy_additions.txt" | xargs -0 -I {} bash -c '{}'

    awk -f "$homed/awk/validate-deletions.awk" "$homed/$id/branch.txt" "$homed/local/deletions.txt" > "$homed/$id/deletions.txt"
    awk 'BEGIN {FS = "\t"} {print $1}' "$homed/$id/deletions.txt" | xargs -r -I {} rm -rf "$dir/{}"
    ;;

# rsync

cleanup-and-reset)
    find "$dir" -printf "%P\t%Ts\t%s\t%y\n" | LC_ALL=C sort > "$homed/$id/base.txt"
    awk -f "$homed/awk/create-branch.awk" -v dir="$dir" -v cur_time="$cur_time" "$homed/$id/branch.txt" "$homed/$id/base.txt" > "$homed/local/base.txt"
    rm -r "$homed/$id"
    ;;

esac
