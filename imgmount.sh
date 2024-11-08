#!/bin/bash

case $1 in
	"-u")
		umount /mnt/bootfs
		umount /mnt/rootfs
		rmdir /mnt/bootfs
		rmdir /mnt/rootfs
		losetup -D
		;;
	*)
		mkdir -p /mnt/imgsync
		losetup -P loop0 $1
		mount /dev/loop0p2 /mnt/imgsync
		mount /dev/loop0p1 /mnt/imgsync/boot/firmware
		;;
esac
