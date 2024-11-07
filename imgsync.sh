#!/bin/bash

# size of boot partition in MiB (default is 512)
bootsize=512

if [ -z "${1}" ]; then
	echo No output filename specified
	exit
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
rsync_options="-aAHXS --info=progress2"

# create empty image file
if ! dd if=/dev/zero of=$outfile bs=1M count=$filesize conv=sparse; then
	echo Error creating image file
	exit
fi

# create partitions inside the image
sfdisk $outfile << EOF
8192,${bootsize}MiB,c
$((bootsize*1024*1024/512)),,
EOF

# setup loop devices
losetup -P loop0 $outfile

# copy boot partition
mkfs.vfat -F32 /dev/loop0p1
fatlabel /dev/loop0p1 bootfs
mkdir -p /mnt/bootfs
mount /dev/loop0p1 /mnt/bootfs
rsync $rsync_options /boot/firmware/ /mnt/bootfs

# create filesystem
mkfs.ext4 -m 0 /dev/loop0p2
e2label /dev/loop0p2 rootfs

mkdir -p /mnt/rootfs
mount /dev/loop0p2 /mnt/rootfs
echo "Base image created and mounted. Starting rsync ..."
rsync $rsync_options --delete \
			--exclude '/var/swap' \
			--exclude '.gvfs' \
			--exclude '/dev/*' \
			--exclude '/mnt/clone/*' \
			--exclude '/proc/*' \
			--exclude '/run/*' \
			--exclude '/sys/*' \
			--exclude '/tmp/*' \
			--exclude 'lost\+found/*' \
			--exclude '/mnt/*' \
		/ /mnt/rootfs

# populate /dev directory
mknod /mnt/rootfs/dev/console c 5 1
mknod /mnt/rootfs/dev/null c 1 3
mknod /mnt/rootfs/dev/zero c 1 5
mknod /mnt/rootfs/dev/full c 1 7
mknod /mnt/rootfs/dev/ptmx c 5 2
mknod /mnt/rootfs/dev/random c 1 8
mknod /mnt/rootfs/dev/urandom c 1 9
mknod /mnt/rootfs/dev/tty c 5 0
mkdir -p /mnt/rootfs/dev/pts
mkdir -p /mnt/rootfs/dev/shm
ln -s /proc/self/fd /mnt/rootfs/dev/fd
ln -s /proc/self/fd/0 /mnt/rootfs/dev/stdin
ln -s /proc/self/fd/1 /mnt/rootfs/dev/stdout
ln -s /proc/self/fd/2 /mnt/rootfs/dev/stderr

# replace PARTUUIDs with new one
newuuid=`sfdisk -d $outfile | grep label-id | sed 's/label-id: 0x\(.*\)/\1/'`
sed -i "s/PARTUUID=.*-02/PARTUUID=$newuuid-02/" /mnt/bootfs/cmdline.txt
sed -i "s/PARTUUID=.*-01\(\s\+\/boot\/firmware\)/PARTUUID=$newuuid-01\1/" /mnt/rootfs/etc/fstab
sed -i "s/PARTUUID=.*-02\(\s\+\/\s\+\)/PARTUUID=$newuuid-02\1/" /mnt/rootfs/etc/fstab

# cleanup
umount /mnt/rootfs
umount /mnt/bootfs
rmdir /mnt/bootfs
rmdir /mnt/rootfs
losetup -d /dev/loop0
sync
