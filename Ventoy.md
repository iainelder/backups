# Ventoy

I discovered Ventoy via a Register article: [Ventory turns any disk in to a multi-boot OS installer](https://www.theregister.com/2021/12/10/friday_foss_fest/).

The latest version just now is 1.0.79.

I download the installer from [GitHub releases](https://github.com/ventoy/Ventoy/releases/tag/v1.0.79) and extract it.

```bash
cdtemp
wget https://github.com/ventoy/Ventoy/releases/download/v1.0.79/ventoy-1.0.79-linux.tar.gz
tar -x -z -f ventoy-1.0.79-linux.tar.gz
cd ventoy-1.0.79/
./Ventoy2Disk.sh
```

Output:

```

**********************************************
      Ventoy: 1.0.79  x86_64
      longpanda admin@ventoy.net
      https://www.ventoy.net
**********************************************

Usage:  Ventoy2Disk.sh CMD [ OPTION ] /dev/sdX
  CMD:
   -i  install Ventoy to sdX (fails if disk already installed with Ventoy)
   -I  force install Ventoy to sdX (no matter if installed or not)
   -u  update Ventoy in sdX
   -l  list Ventoy information in sdX

  OPTION: (optional)
   -r SIZE_MB  preserve some space at the bottom of the disk (only for install)
   -s/-S       enable/disable secure boot support (default is enabled)
   -g          use GPT partition style, default is MBR (only for install)
   -L          Label of the 1st exfat partition (default is Ventoy)
   -n          try non-destructive installation (only for install)


```

You need to tell it the device path of the portable media. YOu can discover it using `findmnt`.

```bash
findmnt /media/isme/Samsung_T5 
```

```text
TARGET                 SOURCE    FSTYPE  OPTIONS
/media/isme/Samsung_T5 /dev/sdb1 fuseblk rw,nosuid,nodev,relatime,user_id=0,group_id=0,default_permission
```

Here goes!

```bash
sudo ./Ventoy2Disk.sh -i /dev/sdb1
```

```

**********************************************
      Ventoy: 1.0.79  x86_64
      longpanda admin@ventoy.net
      https://www.ventoy.net
**********************************************

/dev/sdb1 is a partition, please use the whole disk.
For example:
    sudo sh Ventoy2Disk.sh -i /dev/sdb1 <=== This is wrong
    sudo sh Ventoy2Disk.sh -i /dev/sdb  <=== This is right

```

I mistook the partition for the whole disk. Thankfully the tool gives helpful error messages!

Here goes again.

```bash
sudo ./Ventoy2Disk.sh -i /dev/sdb
```

```

**********************************************
      Ventoy: 1.0.79  x86_64
      longpanda admin@ventoy.net
      https://www.ventoy.net
**********************************************

Disk : /dev/sdb
Model: Samsung Portable SSD T5 (scsi)
Size : 465 GB
Style: MBR


Attention:
You will install Ventoy to /dev/sdb.
All the data on the disk /dev/sdb will be lost!!!

Continue? (y/n) y

All the data on the disk /dev/sdb will be lost!!!
Double-check. Continue? (y/n) y
delete /dev/sdb1

Create partitions on /dev/sdb by parted in MBR style ...
Done
Wait for partitions ...
partition exist OK
create efi fat fs /dev/sdb2 ...
mkfs.fat 4.1 (2017-01-24)
success
Wait for partitions ...
/dev/sdb1 exist OK
/dev/sdb2 exist OK
partition exist OK
Format partition 1 /dev/sdb1 ...
mkexfatfs 1.3.0
Creating... done.
Flushing... done.
File system created successfully.
mkexfatfs success
writing data to disk ...
sync data ...
esp partition processing ...

Install Ventoy to /dev/sdb successfully finished.

```

Looks like it worked!

The Samsung_T5 partition is gone. Now there is a Ventoy partition and it is empty.

```
ls /media/isme/Ventoy/
```

No output.

Ventoy the tool recognises bootable ISO files in the Ventoy partition.

I'll download [Ubuntu 22.04.1](https://ubuntu.com/download/desktop/thank-you?version=22.04.1&architecture=amd64) and [RescueZilla 2.3.1](https://github.com/rescuezilla/rescuezilla/releases/tag/2.3.1).

While those download, I read the [manual](https://www.ventoy.net/en/doc_start.html).

Some details that seem important:

You can place ISO images anywhere. Ventoy will search for all images files.

You can press F2 to directly browse and boot files in local disk.

In secure boot mode you need to enroll a key when booting Ventoy for the first time. The kep to enroll is called ENROLL_THIS_KEY_IN_MOKMANAGER.cer.

Press F3 to enter TreeView mode. Press ESC to return back to List mode.

You can delete Ventoy's secure boot key with a special ISO.

---

I tried to use CloneZilla to make an image of the hard drive. I was expecting to be able to save it in the in the same partition as where the CloneZilla ISO is stored.

Unfortunately it fails when it tries to mount that partition to writre backup. It's the same partition as where CloneZilla is stored and that is already mounted.

```text
Failed to run command: mount /dev/sda1 /mnt/backup

mount: /mnt/backup: /dev/sda1 already mounted or mount point busy
```

Someone else described the problem here on the [Sourceforge forum](https://sourceforge.net/p/rescuezilla/discussion/support/thread/0a12c12d39/?limit=25#79ba).

Ventoy has an option to reserve space for other partitions. So I could reinstall it and give just some of the space to the Ventoy partition and reserve most of the rest for a normal partition for storing files created by CloneZilla or anything else.

I check the sizes of the disks.

```console
$ lsblk --exclude 7
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0 465.8G  0 disk 
├─sda1        8:1    0 465.7G  0 part /media/isme/Ventoy
└─sda2        8:2    0    32M  0 part 
nvme0n1     259:0    0 238.5G  0 disk 
├─nvme0n1p1 259:1    0   260M  0 part /boot/efi
├─nvme0n1p2 259:2    0    16M  0 part 
├─nvme0n1p3 259:3    0 186.3G  0 part /
└─nvme0n1p4 259:4    0  1000M  0 part 
```

It seems that the name of the external drive has changed from sdb to sda. I don't know why.

Device sda is is the external drive. It has a 465.8G capacity.

Device nvme0n1 is the internal drive. It has a 238.5G capacity.

To store a complete image of the internal drive then I would need at least its capacity in free space on the external drive. Let's round it up to 250GB leave some extra space for anything else.

So the size of the Ventoy partition would be = 465.8GB - 250GB = 215.8GB.

I need to express the reserved space in MB. 250GB * 1024MB/GB = 256000MB.

So the install command becomes:

```
sudo ./Ventoy2Disk.sh -I /dev/sda -r 256000
```

Output:

```
**********************************************
      Ventoy: 1.0.79  x86_64
      longpanda admin@ventoy.net
      https://www.ventoy.net
**********************************************

Disk : /dev/sda
Model: Samsung Portable SSD T5 (scsi)
Size : 465 GB
Style: MBR

You will reserve 256000 MB disk space 

Attention:
You will install Ventoy to /dev/sda.
All the data on the disk /dev/sda will be lost!!!

Continue? (y/n) y

All the data on the disk /dev/sda will be lost!!!
Double-check. Continue? (y/n) y

Create partitions on /dev/sda by parted in MBR style ...
Done
Wait for partitions ...
partition exist OK
create efi fat fs /dev/sda2 ...
mkfs.fat 4.1 (2017-01-24)
success
Wait for partitions ...
/dev/sda1 exist OK
/dev/sda2 exist OK
partition exist OK
Format partition 1 /dev/sda1 ...
mkexfatfs 1.3.0
Creating... done.
Flushing... done.
File system created successfully.
mkexfatfs success
writing data to disk ...
sync data ...
esp partition processing ...

Install Ventoy to /dev/sda successfully finished.
```

I copy the ISO files again to the Ventoy partition.

---

This time I was able to make a backup using RescueZilla. It's stored in /media/isme/Storage/Thinkpad.

Because that Storage partition is writable I was able to save the summary as well.

```text
Backup Summary

Backup saved successfully.

Successful backup of partition /dev/nvme0n1p1
Successful backup of partition /dev/nvme0n1p2
Successful backup of partition /dev/nvme0n1p3
Successful backup of partition /dev/nvme0n1p4



Operation took 28.5 minutes.
```

[Jeremy Leik](https://www.youtube.com/watch?v=AIq1vLFwmgY) shows how to restore to a VirtualBox VM using RescueZilla from a backup on network-attached storage.

Restoring from the network looks easy. I made a backup on a USB external disk. I can't share the folder because the RescueZilla ISO lacks the Guest Additions and I can't figure out how to share a USB device with the VM.

Can I make it work this way?
