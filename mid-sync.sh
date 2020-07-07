#!/bin/bash

id=$1
dir=$2
homed=$3

if [ -z "$id" ]
then
    echo "Sync failed: no uuid"
    exit 1
fi

awk -f $homed/awk/merge-deletions.awk $homed/$id/deletions.txt $homed/$id/remote_deletions.txt > $homed/$id/combined_deletions.txt
awk -f $homed/awk/prune-deletions.awk $homed/$id/branch.txt $homed/$id/combined_deletions.txt > $homed/$id/pruned_deletions.txt
