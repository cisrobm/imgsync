# imgsync

Small set of scripts to intelligently back up a running Raspberry Pi installation to an image file. It consists of three scripts:

1. imgsync.sh - Creates an empty disk image file, creates the partitions inside, creates the filesystems and uses rsync to copy the files. It also populates the /dev directory with some required files and updates the /boot/firmware/cmdline.txt and /etc/fstab with the new PARTUUIDs. The resulting disk image will only be as large as necessary.

2. imgwrite.sh - Although the image can be written back simply with dd or the Raspberry Pi imager and expanded using raspi-config, this script will do the filesystem expansion for you.

3. imgmount.sh - Mounts a disk image so it can be accessed via the file system.


Example:

```
sudo imgsync.sh backup.img
```

To write it back:
```
sudo imgwrite.sh backup.img /dev/sdb
```
