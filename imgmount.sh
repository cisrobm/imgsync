#!/bin/bash

mountpoint=/mnt/imgsync

case $1 in
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
