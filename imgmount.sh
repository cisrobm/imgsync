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
		mkdir -p /mnt/bootfs
		mkdir -p /mnt/rootfs
		losetup -P loop0 $1
		mount /dev/loop0p1 /mnt/bootfs
		mount /dev/loop0p2 /mnt/rootfs
		;;
esac
