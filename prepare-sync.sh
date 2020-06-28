#!/bin/bash

id=$1
dir=$2
homed=$3

if [ -z "$id" ]
then
    echo "Sync failed: no uuid"
    exit 1
fi

mkdir -p $homed/$id $homed/local

find $dir -printf "%P\t%Ts\n" | LC_ALL=C sort > $homed/$id/branch.txt

cp -n $homed/$id/branch.txt $homed/local/base.txt

awk -f $homed/awk/find-deletions.awk $homed/local/base.txt $homed/$id/branch.txt > $homed/$id/deletions_tmp.txt

cp -n $homed/$id/deletions_tmp.txt $homed/local/deletions.txt

awk -f $homed/awk/merge-deletions.awk $homed/$id/deletions_tmp.txt $homed/local/deletions.txt > $homed/$id/deletions.txt

rm $homed/$id/deletions_tmp.txt

mv $homed/$id/deletions.txt $homed/local/deletions.txt
