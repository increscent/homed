#!/bin/bash

find ~/tmp -printf "%p\t%Ts\n" | LC_ALL=C sort
rsync -avz ~/tmp ~/tmp1

# rsnapshot
