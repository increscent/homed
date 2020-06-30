#!/bin/bash

host=home
id=$(uuidgen)
local_dir=/home/robert/tmp1
remote_dir=/home/robert/tmp1
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

echo "Pre sync -- local"
$local_homed/pre-sync.sh $id $local_dir $local_homed

echo "Pre sync -- remote"
ssh $host "$remote_homed/pre-sync.sh $id $remote_dir $remote_homed"

scp $host:$remote_homed/$id/deletions.txt $local_homed/$id/remote_deletions.txt
scp $host:$remote_homed/$id/branch.txt $local_homed/$id/remote_branch.txt

awk -f $local_homed/awk/merge-deletions.awk $local_homed/$id/deletions.txt $local_homed/$id/remote_deletions.txt > $local_homed/$id/combined_deletions.txt

awk -f $local_homed/awk/prune-deletions.awk $local_homed/$id/branch.txt $local_homed/$id/combined_deletions.txt > $local_homed/$id/combined_deletions_tmp.txt
awk -f $local_homed/awk/prune-deletions.awk $local_homed/$id/remote_branch.txt $local_homed/$id/combined_deletions_tmp.txt > $local_homed/local/deletions.txt

scp $local_homed/local/deletions.txt $host:$remote_homed/local/deletions.txt

exit 0

# TODO move files instead of deleting them :)
# TODO might need to escape string inside of '{}'
echo "Deleting -- local"
$local_homed/delete-sync.sh $id $local_dir $local_homed

echo "Deleting -- remote"
ssh $host "$remote_homed/delete-sync.sh $id $remote_dir $remote_homed"

rsync -avz $local_dir/ $host:$remote_dir
rsync -avz $host:$remote_dir/ $local_dir

echo "Post sync -- local"
$local_homed/post-sync.sh $id $local_dir $local_homed

echo "Post sync -- remote"
ssh $host "$remote_homed/post-sync.sh $id $remote_dir $remote_homed"

# rsnapshot
