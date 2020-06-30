#!/bin/bash

id=$1
dir=$2
homed=$3

if [ -z "$id" ]
then
    echo "Sync failed: no uuid"
    exit 1
fi

find $dir -printf "%P\t%Ts\n" | LC_ALL=C sort > $homed/local/base.txt

rm -r $homed/$id
