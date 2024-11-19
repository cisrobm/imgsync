# imgsync

Small set of scripts to intelligently back up a running Raspberry Pi installation to an image file. They are written from scratch and have no dependencies that are not installed on a standard Raspberry Pi OS. There are three files:

1. imgsync.sh - Creates an empty disk image file, creates the partitions inside, creates the filesystems and uses rsync to copy the files. It also populates the /dev directory with some required files and updates the /boot/firmware/cmdline.txt and /etc/fstab with the new PARTUUIDs. The resulting disk image will only be as large as necessary. This means it can be restored to a smaller disk if the used space is small enough and also it can be created on the same disk if less than half the space is used. 

If a block device is specified instead of a filename, the behavior is slightly different. First, there will be a safety prompt to prevent the user from inadvertently overwriting a random disk. Then the disk will be partitioned using the entire available space.

2. imgwrite.sh - Although the image can be written back simply with dd or the Raspberry Pi imager and expanded after booting using raspi-config, this script will do the filesystem expansion for you.

3. imgmount.sh - Mounts a disk image so it can be accessed via the file system.


Example:

```
sudo ./imgsync.sh backup.img
```

To write it back:
```
sudo ./imgwrite.sh backup.img /dev/sdb
```
