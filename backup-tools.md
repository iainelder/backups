# Backup tools

I want something that will back up all the files I have on my Ubuntu disk
partition and put it on S3. What can do that?

## Available Tools

Search in the Ubuntu Software application for \[backup\].

### restic

* [restic](https://github.com/restic/restic) only supports path-based S3 URLs.
  AWS has not yet confirmed a deprecation date for path-based URLs in favor of
  virtual-host-based URLs. So this may be a good option.

Latest release in apt repo:
[0.9.6](https://github.com/restic/restic/releases/tag/v0.9.6), released
2019-11-29.

Latest release on Github:
[0.13.1](https://github.com/restic/restic/releases/tag/v0.9.6), released
2022-04-12.

Example restic config:  
https://www.redhat.com/sysadmin/backup-Restic

### Timeshift

[Timeshift](https://github.com/teejee2008/timeshift) is similar to applications
like rsnapshot, BackInTime and TimeVault but with different goals. It is
designed to protect only system files and settings. User files such as
documents, pictures and music are excluded. This ensures that your files remains
unchanged when you restore your system to an earlier date.

### Backintime

[backintime](https://github.com/bit-team/backintime) only supports local and
SSH. Maybe possible to use S3 FTP interface, but it sounds complicated.

### rdiff-backup

Mentioned here:  
https://askubuntu.com/questions/963442/backup-ext4-data-to-exfat-partition

### Borg backup

Mentioned here:  
https://askubuntu.com/questions/963442/backup-ext4-data-to-exfat-partition

> If you use Borg Backup, it will actually keep track of ownership and
> permissions without the file system in the backup location having to support
> ownership or permissions as those are encapsulated by Borg.

> I simply use date +%c for archive names because my backups are created
> automatically.

I will try this one first.

https://github.com/borgbackup/borg

Latest release in apt repo:
[1.1.15](https://github.com/borgbackup/borg/releases/tag/1.1.15), from
2020-12-25.

Latest release on Github:
[1.2.0](https://github.com/borgbackup/borg/releases/tag/1.2.0), released
2022-02-22.

See notes on [borg](borg.md).

## What am I talking about?

What is a disk, partition, filesystem, device, volume, mount?

Summarizing [Ubuntu's explanation](https://help.ubuntu.com/stable/ubuntu-help/disk-partitions.html.en):

* disk: a physical storage device
* partition: whole or part of a disk
* mount: the act of making storage accessible
* volume: storage accessible to Ubuntu

In the Disks utility the left column lists disks and the right panel draws
volumes labelled as partitions and file systems.

Each volume is mounted at a point in the "file system hierarchy".

A device in the Linux kernel is a software interface to hardware. It might be a
hard disk, it might be floppy disk, it might be a mouse, any bit of hardware and
not necessarily storage.

Linux addresses each disks and partition with its own device. `hda` is the first
IDE hard disk, `hdb` is the second IDE hard disk. `sda` is the first SCSI hard
disk, `sdb` is the second SCSI hard disk. `hda1` is the first partition of the
first IDE hard disk. `hda2` is the second partition of the first IDE hard disk.
And so on.

SCSI and IDE are different ways of connecting a disk to a computer.

List of devices in linux (things in the /dev folder)  
https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/devices.txt

## My environment

How many disks do I have? How many disk partitions do I have? Which file systems
do they use? How often do I want to back up? Where do I want to back up to?

I have one disk with four partitions. I want to backup just the partition
mounted at `/`. Its device ID is nvme0n1p3. It uses the ext4 file system.

I want to back up to my external hard disk. It has a single partition. It is
mounted at `/media/isme/Samsung_T5`. Its device ID is sdb1. It uses the exfat
file system.

See below for how I got those answers.

### How do I back up from ext4 to exfat?

The backup disk uses a different filesystem (exfat) from the source device
(ext4). What problems might that cause for restoring the data?

I found a discussion on Ask Ubuntu:  
https://askubuntu.com/questions/963442/backup-ext4-data-to-exfat-partition

Exfat doesn't have journaling. That could risk the integrity of the data if
there were a power failure. It is, however, compatible with macOS and Windows
without requiring the installation of extra hardware.

Ext4 has journaling. There are tools available fo macOS and Windows that can
read and write it.

For now I will just use the stock exfat file system for my first go.

### Which backup tools will I use?

I really like the sound of borgbackup. It seems like a more mature version of
restic. Restic has native S3 support, but actually at this point I don't need
that. I want to make a back up to my external disk before doing anything fancy
like backup over the network. ("Walk before you can run.")

### How often do I want to back up?

I guess I want to back up as often as changes are made. But I save text files
really frequently and I guess I don't need every single little edit being sent
up to server. (I use git commits for that when I have something I'm sure I want
to keep.)

So an hourly backup would be good enough and it seems that most tools support
that (are they creating cron jobs in the background?). A cron-based schedule
would be good enough for me for now. (It's better than what I have at the
moment, which is never.)

### How many disks/partitions/filesystems do I have?

Commands to collect this information:

*
  [`sudo fdisk --list`](https://manpages.ubuntu.com/manpages/focal/en/man8/fdisk.8.html)
  to list the partition tables in `/proc/partitions`
* [`df`](https://manpages.ubuntu.com/manpages/focal/en/man1/df.1.html) to report
  file system disk space usage
* [`lsblk]()
* Disks utility (Ubuntu desktop application)

First I checked the disk utility as it's the easiest way to explore.

There is one disk, model "SAMSUNG MZVLW256HEHP-000L7 (5L7QCXB7)".

There are four partitions (volumes) (Device, Partition Type or contents if unallocated):

* /dev/nvme0n1p1, EFI System (System)
* /dev/nvme0n1p2, Microsoft Reserved
* /dev/nvme0n1p3, Linux Filesystem
* /dev/nvme0n1, Unallocated Space
* /dev/nvme0n1p4, Microsoft Windows Recovery Environment (System)

lsblk gives useful concise output.

```
$ lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
loop0         7:0    0     4K  1 loop /snap/bare/5
loop1         7:1    0  55.5M  1 loop /snap/core18/2284
loop2         7:2    0 247.9M  1 loop /snap/gnome-3-38-2004/87
loop3         7:3    0  44.7M  1 loop /snap/snapd/15534
loop4         7:4    0   219M  1 loop /snap/gnome-3-34-1804/77
loop5         7:5    0 295.7M  1 loop /snap/vlc/2344
loop6         7:6    0 295.6M  1 loop /snap/vlc/2288
loop7         7:7    0  43.6M  1 loop /snap/snapd/15177
loop8         7:8    0  54.2M  1 loop /snap/snap-store/558
loop9         7:9    0    51M  1 loop /snap/snap-store/547
loop10        7:10   0 248.8M  1 loop /snap/gnome-3-38-2004/99
loop11        7:11   0  61.9M  1 loop /snap/core20/1405
loop12        7:12   0  61.9M  1 loop /snap/core20/1376
loop13        7:13   0  65.1M  1 loop /snap/gtk-common-themes/1515
loop14        7:14   0  65.2M  1 loop /snap/gtk-common-themes/1519
loop15        7:15   0  55.5M  1 loop /snap/core18/2344
loop16        7:16   0   219M  1 loop /snap/gnome-3-34-1804/72
sdb           8:16   0 465.8G  0 disk 
└─sdb1        8:17   0 465.8G  0 part /media/isme/Samsung_T5
nvme0n1     259:0    0 238.5G  0 disk 
├─nvme0n1p1 259:1    0   260M  0 part /boot/efi
├─nvme0n1p2 259:2    0    16M  0 part 
├─nvme0n1p3 259:3    0 186.3G  0 part /
└─nvme0n1p4 259:4    0  1000M  0 part 
```

To understand `MAJ:MIN`, refer to the Linux device documentation linked above.

lsblk lists only block devices. Character devices are ignored.

Major 7 block devices are all loopback devices. They are used to mount
filesystems not associated with block devices. They are used by Ubuntu's snaps.
I want to exclude these.

This is better:

```
$ lsblk --exclude 7
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sdb           8:16   0 465.8G  0 disk 
└─sdb1        8:17   0 465.8G  0 part /media/isme/Samsung_T5
nvme0n1     259:0    0 238.5G  0 disk 
├─nvme0n1p1 259:1    0   260M  0 part /boot/efi
├─nvme0n1p2 259:2    0    16M  0 part 
├─nvme0n1p3 259:3    0 186.3G  0 part /
└─nvme0n1p4 259:4    0  1000M  0 part 
```

The tree output is nice visually but would make it harder to parse. by
outputting a flattened JSON list I can parse it with other tools! Here's it is
presented as a table.

```
$ lsblk --exclude 7 --list --json | jq .blockdevices | jtbl -m
| name      | maj:min   | rm    | size   | ro    | type   | mountpoint             |
|-----------|-----------|-------|--------|-------|--------|------------------------|
| sdb       | 8:16      | False | 465.8G | False | disk   |                        |
| sdb1      | 8:17      | False | 465.8G | False | part   | /media/isme/Samsung_T5 |
| nvme0n1   | 259:0     | False | 238.5G | False | disk   |                        |
| nvme0n1p1 | 259:1     | False | 260M   | False | part   | /boot/efi              |
| nvme0n1p2 | 259:2     | False | 16M    | False | part   |                        |
| nvme0n1p3 | 259:3     | False | 186.3G | False | part   | /                      |
| nvme0n1p4 | 259:4     | False | 1000M  | False | part   |                        |
```

Use `lsblk --help | less` to look up what the columns mean. Use the following
command to show the values for all the columns so that you can select the
meaningful ones. Output omitted for brevity.

```
lsblk --exclude 7 --list --json --output-all | jq . | less
```

To reproduce the output of the Disks utility:

Disks:

```bash
lsblk \
--exclude 7 \
--list \
--json \
--output TYPE,MODEL,SIZE,PTTYPE,SERIAL,NAME \
| jq -c '.blockdevices[] | select(.type == "disk") | del(.type)' \
| jtbl -m
```

| model                      | size   | pttype   | serial          | name    |
|----------------------------|--------|----------|-----------------|---------|
| Samsung_Portable_SSD_T5    | 465.8G | dos      | S49XNR0NC09286P | sdb     |
| SAMSUNG MZVLW256HEHP-000L7 | 238.5G | gpt      | S35ENX0K849159  | nvme0n1 |

This lacks the firmware ID. See below.

Partitions:

```bash
lsblk \
--exclude 7 \
--list \
--json \
--output TYPE,SIZE,PTTYPE,NAME,PARTTYPE,UUID,FSTYPE,MOUNTPOINT \
| jq -c '.blockdevices[] | select(.type == "part") | del(.type)' \
| jtbl -m
```

| size   | pttype   | name      | parttype                             | uuid                                 | fstype   | mountpoint             |
|--------|----------|-----------|--------------------------------------|--------------------------------------|----------|------------------------|
| 465.8G | dos      | sdb1      | 0x7                                  | 7840-0938                            | exfat    | /media/isme/Samsung_T5 |
| 260M   | gpt      | nvme0n1p1 | c12a7328-f81f-11d2-ba4b-00a0c93ec93b | 5C86-75CE                            | vfat     | /boot/efi              |
| 16M    | gpt      | nvme0n1p2 | e3c9e316-0b5c-4db8-817d-f92df00215ae |                                      |          |                        |
| 186.3G | gpt      | nvme0n1p3 | 0fc63daf-8483-4772-8e79-3d69d8477de4 | 02e1be6b-fecb-4b7b-8f83-2fabdae24dee | ext4     | /                      |
| 1000M  | gpt      | nvme0n1p4 | de94bba4-06d1-4d40-a16a-bfd50179d6ac | E08C89968C8967BC                     | ntfs     |                        |

Disks knows how to convert the partition type UUID into something
human-readable. I don't, but you can look them up online.

### Firmware

I don't know how to get the values that Disks displays in parenthesis after the
model. They don't appear in "output-all" mode.

The values are:

* 5L7QCXB7 (Searching on Google suggests it's related to the firmware)
* MVT42P1Q (Found a match in a disk database. It's the firmware ID)

Disk database:  
https://smarthdd.com/database/Samsung-Portable-SSD-T5/MVT42P1Q/

lsblk doesn't offer firmware information. But hdparm does:

https://manpages.ubuntu.com/manpages/xenial/man8/hdparm.8.html

And smartmontools:  
https://linuxconfig.org/obtain-hard-drive-firmware-information-using-linux-and-smartctl

### Assessment

Disks shows an "assessment" of the external disk: "Disk is OK (24° C / 75° F)".

It knows the temperature of the disk. I think this is something I can get with
smartctl of smartmontools.

```bash
smartctl --all /dev/nvme0n1 | less
```

```text
=== START OF INFORMATION SECTION ===
Model Number:                       SAMSUNG MZVLW256HEHP-000L7
Serial Number:                      S35ENX0K849159
Firmware Version:                   5L7QCXB7
[...]

=== START OF SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

SMART/Health Information (NVMe Log 0x02)
Critical Warning:                   0x00
Temperature:                        27 Celsius
[...]
```

smartctl also has a JSON output mode. I think it could show all the information
I would ever need to collect. But I've gone far enough down this rabbit hole. I
think I know enough now to get on with the main task of making a damn backup!
