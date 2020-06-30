#!/bin/bash

host=home
id=$(uuidgen)
local_dir=/home/robert/Documents
remote_dir=/home/robert/tmp/Documents
local_homed=/home/robert/homed
remote_homed=/home/robert/homed

cd $local_homed

if [ -z "$id" ]
then
    echo "Sync failed: no uuid"
    exit 1
fi

ssh $host bash -c "uname -a" > /dev/null

if [ $? -ne 0 ]
then
    echo "Sync failed: cannot connect to host"
    exit 1
fi

echo "Preparing sync -- local"
$local_homed/prepare-sync.sh $id $local_dir $local_homed

echo "Preparing sync -- remote"
ssh $host "$remote_homed/prepare-sync.sh $id $remote_dir $remote_homed"

exit 0

awk -f awk/merge-deletions.awk tmp/tmp1_total_deletions.txt tmp/tmp2_total_deletions.txt > tmp/combined_total_deletions.txt

awk -f awk/prune-deletions.awk tmp/tmp1_branch.txt tmp/combined_total_deletions.txt > tmp/combined_total_deletions_tmp.txt
awk -f awk/prune-deletions.awk tmp/tmp2_branch.txt tmp/combined_total_deletions_tmp.txt > tmp/combined_total_deletions.txt

rm tmp/combined_total_deletions_tmp.txt
cp tmp/combined_total_deletions.txt tmp/tmp1_total_deletions.txt
cp tmp/combined_total_deletions.txt tmp/tmp2_total_deletions.txt

# TODO move files instead of deleting them :)
# TODO might need to escape string inside of '{}'
awk 'BEGIN {FS = "\t"} {print $1}' tmp/combined_total_deletions.txt | xargs -I {} rm -rf ~/tmp/tmp1/{}
awk 'BEGIN {FS = "\t"} {print $1}' tmp/combined_total_deletions.txt | xargs -I {} rm -rf ~/tmp/tmp2/{}

rsync -avz ~/tmp/tmp1/ ~/tmp/tmp2/
rsync -avz ~/tmp/tmp2/ ~/tmp/tmp1/

find ~/tmp/tmp1 -printf "%P\t%Ts\n" | LC_ALL=C sort > tmp/tmp1_base.txt
find ~/tmp/tmp2 -printf "%P\t%Ts\n" | LC_ALL=C sort > tmp/tmp2_base.txt

rm tmp/tmp1_branch.txt
rm tmp/tmp2_branch.txt

# rsnapshot
