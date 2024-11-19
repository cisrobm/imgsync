#!/bin/bash

# size of boot partition in MiB (default is 512)
bootsize=512

bootmountpoint=/mnt/bootfs
rootmountpoint=/mnt/rootfs

if [ -z "${1}" ]; then
	echo No output filename specified
	exit 1
fi

outfile=$1
filename="${outfile##*/}"
path=`dirname $1`

if [ -z "${path}" ]; then
	path="."
fi

# calculate required size for the image file
disk_used=`df --output=used -k / | tail -1`
filesize=$(((disk_used*101/100)/1024+$bootsize))

#rsync_options="--force -rltWDEHXAgoptx"
rsync_options="-aAHXSDW --no-compress --no-checksum --info=progress2"

if ! ( mkdir -p $bootmountpoint || mkdir -p $rootmountpoint ); then
	exit 1
fi

# is it a block device?
if [ -b $outfile ]; then
        read -p "Are you sure you want to write to ${outfile}?"$'\n'"ALL DATA ON ${outfile} WILL BE DESTROYED!"$'\n'"Proceed? [Y/N] " yn
	case $yn in
		y) ;&
		Y) ;;
		*) echo "Understandable. Have a nice day."; exit 1;;
	esac

	echo "Creating partitions ..."
	sfdisk "$outfile" <<- EOF
	8192,${bootsize}MiB,c
	$((bootsize*1024*1024/512)),,
	EOF

	echo "Creating boot filesystem ..."
	mkfs.vfat -F32 ${outfile}1
	fatlabel ${outfile}1 bootfs
	mount ${outfile}1 $bootmountpoint
	mkfs.ext4 -m 0 ${outfile}2
	e2label ${outfile}2 rootfs
	mount ${outfile}2 $rootmountpoint

# not a block device
else
	# create empty image file
	if ! dd if=/dev/zero of=$outfile bs=1M count=$filesize conv=sparse; then
		echo Error creating image file
		exit 1
	fi

	# create partitions inside the image
	sfdisk $outfile <<- EOF
	8192,${bootsize}MiB,c
	$((bootsize*1024*1024/512)),,
	EOF

	# setup loop devices
	if ! losetup -P loop0 $outfile; then
		echo losetup failed.
		exit 1
	fi

	# create boot filesystem and mount it
	mkfs.vfat -F32 /dev/loop0p1
	fatlabel /dev/loop0p1 bootfs
	mount /dev/loop0p1 $bootmountpoint

	# create root filesystem and mount it
	mkfs.ext4 -m 0 /dev/loop0p2
	e2label /dev/loop0p2 rootfs
	mount /dev/loop0p2 $rootmountpoint
fi

echo "Copying bootfs contents ..."
rsync $rsync_options /boot/firmware/ $bootmountpoint

echo "Copying rootfs contents ..."
rsync $rsync_options --delete \
			--exclude '.gvfs' \
			--exclude '/dev/*' \
			--exclude '/mnt/clone/*' \
			--exclude '/proc/*' \
			--exclude '/run/*' \
			--exclude '/sys/*' \
			--exclude '/tmp/*' \
			--exclude 'lost\+found/*' \
			--exclude '/mnt/*' \
   			--exclude '/var/swap' \
		/ $rootmountpoint

# populate /dev directory
mknod $rootmountpoint/dev/console c 5 1
mknod $rootmountpoint/dev/null c 1 3
mknod $rootmountpoint/dev/zero c 1 5
mknod $rootmountpoint/dev/full c 1 7
mknod $rootmountpoint/dev/ptmx c 5 2
mknod $rootmountpoint/dev/random c 1 8
mknod $rootmountpoint/dev/urandom c 1 9
mknod $rootmountpoint/dev/tty c 5 0
mkdir -p $rootmountpoint/dev/pts
mkdir -p $rootmountpoint/dev/shm
ln -s /proc/self/fd $rootmountpoint/dev/fd
ln -s /proc/self/fd/0 $rootmountpoint/dev/stdin
ln -s /proc/self/fd/1 $rootmountpoint/dev/stdout
ln -s /proc/self/fd/2 $rootmountpoint/dev/stderr

# update PARTUUIDs
newuuid=`sfdisk -d $outfile | grep label-id | sed 's/label-id: 0x\(.*\)/\1/'`
sed -i "s/PARTUUID=.*-02/PARTUUID=$newuuid-02/" $bootmountpoint/cmdline.txt
sed -i "s/PARTUUID=.*-01\(\s\+\/boot\/firmware\)/PARTUUID=$newuuid-01\1/" $rootmountpoint/etc/fstab
sed -i "s/PARTUUID=.*-02\(\s\+\/\s\+\)/PARTUUID=$newuuid-02\1/" $rootmountpoint/etc/fstab

# cleanup
umount $rootmountpoint
umount $bootmountpoint
rmdir $bootmountpoint
rmdir $rootmountpoint
losetup -d /dev/loop0
sync
