#!/bin/bash

host=home
id=$(uuidgen)
local_dir=/home/robert/tmp/tmp1
remote_dir=/home/robert/tmp1
local_homed=/home/robert/homed
remote_homed=/home/robert/homed

# homed/local/deletions.txt         saved deletions for previous/future run
# homed/$id/deletions.txt           working deletions for current run
# homed/$id/pruned_deletions.txt    working pruned deletions for current run

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
scp $local_homed/$id/deletions.txt $host:$remote_homed/$id/remote_deletions.txt

echo "Mid sync -- local"
$local_homed/mid-sync.sh $id $local_dir $local_homed

echo "Mid sync -- remote"
ssh $host "$remote_homed/mid-sync.sh $id $remote_dir $remote_homed"

scp $host:$remote_homed/$id/pruned_deletions.txt $local_homed/$id/remote_pruned_deletions.txt
scp $local_homed/$id/pruned_deletions.txt $host:$remote_homed/$id/remote_pruned_deletions.txt

echo "Next sync -- local"
$local_homed/next-sync.sh $id $local_dir $local_homed

echo "Next sync -- remote"
ssh $host "$remote_homed/next-sync.sh $id $remote_dir $remote_homed"

# TODO move files instead of deleting them :)
# TODO might need to escape string inside of '{}'
echo "Deleting -- local"
$local_homed/delete-sync.sh $id $local_dir $local_homed

echo "Deleting -- remote"
ssh $host "$remote_homed/delete-sync.sh $id $remote_dir $remote_homed"

echo "rsync -- local -> remote"
rsync -avz $local_dir/ $host:$remote_dir

echo "rsync -- remote -> local"
rsync -avz $host:$remote_dir/ $local_dir

echo "Post sync -- local"
$local_homed/post-sync.sh $id $local_dir $local_homed

echo "Post sync -- remote"
ssh $host "$remote_homed/post-sync.sh $id $remote_dir $remote_homed"

# rsnapshot
