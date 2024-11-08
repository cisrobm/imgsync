#!/bin/bash

case $1 in
	"-u")
		umount /mnt/imgsync/boot/firmware
		umount /mnt/imgsync
		rmdir /mnt/imgsync
		losetup -D
		;;
	*)
		mkdir -p /mnt/imgsync
		losetup -P loop0 $1
		mount /dev/loop0p2 /mnt/imgsync
		mount /dev/loop0p1 /mnt/imgsync/boot/firmware
		;;
esac
