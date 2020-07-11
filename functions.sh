#!/bin/bash

id=$2
dir=$3
homed=$4

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

find-deletions)
    mkdir -p "$homed/$id" "$homed/local" "$dir"

    find "$dir" -printf "%P\t%Ts\n" | LC_ALL=C sort > "$homed/$id/branch.txt"

    cp -n "$homed/$id/branch.txt" "$homed/local/base.txt"

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

delete)
    awk 'BEGIN {FS = "\t"} {print $1}' "$homed/local/deletions.txt" | xargs -I {} rm -rf "$dir/{}"
    ;;

# rsync

cleanup-and-reset)
    rm -r "$homed/$id"
    find "$dir" -printf "%P\t%Ts\n" | LC_ALL=C sort > "$homed/local/base.txt"
    ;;

esac
