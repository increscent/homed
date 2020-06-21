#!/bin/bash

find ~/tmp1 -printf "%P\t%Ts\n" | LC_ALL=C sort > tmp1_branch.txt
find ~/tmp2 -printf "%P\t%Ts\n" | LC_ALL=C sort > tmp2_branch.txt

./sorted-diff/sorted-diff normal tmp1_base.txt tmp1_branch.txt tmp1_additions.txt tmp1_deletions.txt
./sorted-diff/sorted-diff normal tmp2_base.txt tmp2_branch.txt tmp2_additions.txt tmp2_deletions.txt

./sorted-diff/sorted-merge tmp1_total_deletions.txt tmp1_deletions.txt > tmp1_total_deletions_tmp.txt
./sorted-diff/sorted-merge tmp2_total_deletions.txt tmp2_deletions.txt > tmp2_total_deletions_tmp.txt

rm tmp1_additions.txt
rm tmp2_additions.txt
rm tmp1_deletions.txt
rm tmp2_deletions.txt

mv tmp1_total_deletions_tmp.txt tmp1_total_deletions.txt
mv tmp2_total_deletions_tmp.txt tmp2_total_deletions.txt

./sorted-diff/sorted-merge tmp1_total_deletions.txt tmp2_total_deletions.txt > combined_total_deletions.txt

./sorted-diff/sorted-diff modified tmp1_branch.txt combined_total_deletions.txt combined_total_deletions_tmp.txt /dev/null
./sorted-diff/sorted-diff modified tmp2_branch.txt combined_total_deletions_tmp.txt combined_total_deletions.txt /dev/null

rm combined_total_deletions_tmp.txt
cp combined_total_deletions.txt tmp1_total_deletions.txt
cp combined_total_deletions.txt tmp2_total_deletions.txt

# TODO move files instead of deleting them :)
awk 'BEGIN {FS = "\t"} {print $1}' combined_total_deletions.txt | xargs -I {} rm -rf ~/tmp1/{}
awk 'BEGIN {FS = "\t"} {print $1}' combined_total_deletions.txt | xargs -I {} rm -rf ~/tmp2/{}

rsync -avz ~/tmp1/ ~/tmp2/
rsync -avz ~/tmp2/ ~/tmp1/

mv tmp1_branch.txt tmp1_base.txt
mv tmp2_branch.txt tmp2_base.txt

# rsnapshot
