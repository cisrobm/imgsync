# imgsync

Small set of scripts to intelligently back up a running Raspberry Pi installation to an image file.

Example:

```
sudo imgsync.sh backup.img
```

To write it back:
```
sudo imgwrite.sh backup.img /dev/sdb
```
