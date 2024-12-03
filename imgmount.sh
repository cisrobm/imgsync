#!/bin/bash

mountpoint=/mnt/imgsync

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

case $1 in
	"")
		echo "Usage: $0 [imgfile] | $0 -u"
		;;
	"-u")
		umount $mountpoint/boot/firmware
		umount $mountpoint
		rmdir $mountpoint
		losetup -D
		;;
	*)
		mkdir -p $mountpoint
		losetup -P loop0 $1
		mount /dev/loop0p2 $mountpoint
		mount /dev/loop0p1 $mountpoint/boot/firmware
		;;
esac
