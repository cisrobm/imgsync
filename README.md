# imgsync

Small set of scripts to intelligently back up a running Raspberry Pi installation to an image file. It works by creating an empty disk image file, creating the partitions inside, and using rsync to copy the files. The resulting image will be only as big as required. After writing the image, the filesystem will be expanded again to use the entire disk.

Example:

```
sudo imgsync.sh backup.img
```

To write it back:
```
sudo imgwrite.sh backup.img /dev/sdb
```
