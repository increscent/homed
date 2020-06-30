#!/bin/bash

id=$1
dir=$2
homed=$3

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

awk 'BEGIN {FS = "\t"} {print $1}' $homed/local/deletions.txt | xargs -I {} rm -ri '$dir/{}'
