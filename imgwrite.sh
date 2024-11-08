#!/bin/bash

# size of boot partition in MiB, default is 512
bootsize=512

dd if=$1 of=$2 bs=1M status=progress
sfdisk --delete $2 2
sfdisk -a $2 << EOF
$((bootsize*1024*1024/512)),,
EOF
e2fsck -f ${2}2
resize2fs ${2}2
