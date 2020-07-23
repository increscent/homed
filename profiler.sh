#!/bin/bash

sudo tcpdump -i wlp4s0 'port 22' > tmp.txt
awk 'BEGIN {FS = ","} {print $NF}' tmp.txt | awk '{total += $2} END {print total}'
rm tmp.txt
