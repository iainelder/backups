# Borg Remote Backup on Hetzner

Hetzer offers a managed remote backup service using borg.

Borg backups are available as part of Hetzner's storage box service.

Hetzner has published a guide to get started and general documentation for the
storage box service.

* [Install and Configure BorgBackup](https://community.hetzner.com/tutorials/install-and-configure-borgbackup).
* [Storage Box SSH Keys](https://docs.hetzner.com/robot/storage-box/backup-space-ssh-keys/)
* [Access with SSH/rsync/BorgBackup](https://docs.hetzner.com/robot/storage-box/access/access-ssh-rsync-borg)

I have signed up for a 1TB storage box that costs EUR 3 per month.

I chose Hetzner because they are based in the EU and so if they charge me any
VAT I can reclaim it.

I can log in with user the user name and password shown in the "robot" console.

The shell is restricted to commands that operate on files. No redirection or
pipes are allowed.

```
u111111 /home > help
+---------------------------------------------------------------------------+
| The following commands are available:                                     |
|   ls                                  list directory content              |
|   tree                                list directory content              |
|   cd                                  change current working directory    |
|   pwd                                 show current working directory      |
|   mkdir                               create new directory                |
|   rmdir                               delete directory                    |
|   du                                  disk usage of files/directories     |
|   df                                  show disk usage                     |
|   dd                                  read and write files                |
|   cat                                 output file content                 |
|   touch                               create new file                     |
|   cp                                  copy files/directories              |
|   rm                                  delete files/directories            |
|   mv                                  move files/directories              |
|   chmod                               change file/directory permissions   |
|   md5|sha1|sha256|sha512              create hash sum of file             |
|   md5sum|sha1sum|sha256sum|sha512sum  create hash sum of file             |
|                                                                           |
| Available as server side backend:                                         |
|   borg                                                                    |
|   rsync                                                                   |
|   scp                                                                     |
|   sftp                                                                    |
|                                                                           |
| Please note that this is only a restricted shell which do not             |
| support shell features like redirects or pipes.                           |
|                                                                           |
| You can find more information in our Docs:                                |
|   https://docs.hetzner.com/robot/storage-box/                             |
+---------------------------------------------------------------------------+
```

I can't copy my SSH key using ssh-copy-id because Hetzner requires the `-s`
option and my version of ssh-copy-id doesn't have it.

```
$ ssh-copy-id -p 23 u111111@u111111.your-storagebox.de
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 2 key(s) remain to be installed -- if you are prompted now it is to install the new keys
u111111@u111111.your-storagebox.de's password: 

+----------------------------------------------------------------------------+
| ssh-copy-id is only supported with the "-s" argument.                      |
| Please try to rerun your command like this:                                |
|                                                                            |
|   ssh-copy-id -p 23 -s u111111@u111111.your-storagebox.de                  |
|                                                                            |
| Please note that the "-s" argument is only supported with OpenSSH 8.5+.    |
|                                                                            |
| You can find more details and a manual guide for the SSH key configuration |
| on this page:                                                              |
| https://docs.hetzner.com/robot/storage-box/backup-space-ssh-keys/          |
+----------------------------------------------------------------------------+
```

Ubuntu 20.04 ships with OpenSSH 8.2.

I can upload the key using ssh and scp.

My config for Hetzner:

```
Host hetzner
    Hostname u111111.your-storagebox.de
    User u111111
    Port 23
```

Allows me to log in like this: `ssh hetner`.

Init a borg directory.

```
borg init \
--encryption=repokey \
ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad
```

It prints some info about old version that I think doesn't matter.

```
Enter new passphrase: 
Enter same passphrase again: 
Do you want your passphrase to be displayed for verification? [yN]: 

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad

See https://borgbackup.readthedocs.io/en/stable/changes.html#pre-1-0-9-manifest-spoofing-vulnerability for details about the security implications.
```

And a warning about repokey mode.

```
IMPORTANT: you will need both KEY AND PASSPHRASE to access this repo!
If you used a repokey mode, the key is stored in the repo, but you should back it up separately.
Use "borg key export" to export the key, optionally in printable format.
Write down the passphrase. Store both at safe place(s).
```

The key is stored in the repo. Is this apart from the password?

Export `BORG_REPO` environment variable to save me having to type the name all
the time.

```bash
export BORG_REPO="ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad"
```

Now I can create a test repo.

```console
$ borg create ::test_archive ~/Imágenes/
Enter passphrase for key ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad: 
```

And I can list it.

```console
$ borg create ::test_archive ~/Imágenes/
Enter passphrase for key ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad: 
```

I need to enter the password for every operation. That's annoying. I will need
to avoid that to automate the backups. There is a long list of suggestions for
dealing with this. Unfortunately the easiest one is just to embed the password
in the backup script. See
[How can I specify the encryption passphrase automatically?](https://borgbackup.readthedocs.io/en/stable/faq.html#how-can-i-specify-the-encryption-passphrase-programmatically).
I will solve this later after doing a one-time full backup.

When I SSH into the storage box I can see the borg backup folder.

```console
$ ssh hetzner 
...
u111111 /home > ls backups/thinkpad
README		data		index.5		nonce
config		hints.5		integrity.5
```

To mak a full system backup, Hetzner recommends excluding some directories.
According to
[Ubuntu's interpretation of the filesystem hierarchy standard](https://help.ubuntu.com/community/LinuxFilesystemTreeOverview),
these are:

* /dev - device files, not regular files but refer to hardware devices
* /proc - a way for the kernel to send information to processes
* /sys - the kernel's view of the system
* /var/run - /var is persistent variable data. /var/run is not described
* /run - ephemeral run time data cleared at boot time. deprecates /var/run
* /lost+found - is not described (see below)
* /mnt - a place for mount points
* /var/lib/lxcfs - not described

Ubuntu symlinks /var/run to /run, so I don't need to include both.

Ubuntu also has /media for mount points.

Should /tmp be excluded or not? I don't use it for anything because I use ~/tmp
for this purpose.

[/lost+found](https://unix.stackexchange.com/a/18157/48038) is where fsck puts
recovered data fragements missing from the file system.

[/var/lib](https://www.pathname.com/fhs/pub/fhs-2.3.html#VARLIBVARIABLESTATEINFORMATION)
is for "variable state information". It is used to preserve the condition of an
application between invocation and between different instances of the same
application.

[lxcfs](https://github.com/lxc/lxcfs) is a FUSE filesystem written with the
intention of making Linux containers feel more like a virtual machine. It's
[packaged in Ubuntu](https://ubuntu.com/blog/introducing-lxcfs), but I don't
appear to have it installed as the directory /var/lib/lxcfs does not exist. I
suppose I can ignore this one for now.

I can probably ignore the swapfile as well.

So the full command to backup the full system with basic timing and logging would be:

```bash
time \
sudo --preserve-env=BORG_REPO,BORG_RSH \
borg create --verbose --progress --stats \
::full_system_'{now:%Y-%m_%d_%H:%M}' \
/ \
--exclude /dev \
--exclude /proc \
--exclude /sys \
--exclude /run \
--exclude /lost+found \
--exclude /mnt \
--exclude /media \
--exclude /tmp \
--exclude /swapfile \
| tee ~/tmp/borg_create_log.txt
```

How do I make Ubuntu stay awake for such a long operation? In
the power settings Ubuntu does not suspend automatically when it is plugged in.
So I think I am safe here.

Now to execute it!

Of course, unless running as root I can't access all the folders! This is what happened before using sudo.

```
Enter passphrase for key ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad: 
Creating archive at "ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad::full_system_2022-07_23_13:01"
/boot/efi: dir_open: [Errno 13] Permission denied: 'efi'g                       
/boot/System.map-5.11.0-46-generic: open: [Errno 13] Permission denied: 'System.map-5.11.0-46-generic'
/boot/System.map-5.8.0-63-generic: open: [Errno 13] Permission denied: 'System.map-5.8.0-63-generic'
^CLocal ExceptionMB C 20.47 MB D 286 N boot/initrd.img-5.11.0-46-generic        
```

And when running as root I don't have access to my default SSH key.

```
The authenticity of host '[u111111.your-storagebox.de]:23 ([78.47.193.188]:23)' can't be established.
ECDSA key fingerprint is SHA256:oDHZqKXnoMtgvPBjjC57pcuFez28roaEuFcfwyg8O5c.
Are you sure you want to continue connecting (yes/no/[fingerprint])? 
Remote: Host key verification failed.
Connection closed by remote host. Is borg working on the server?
```

So export BORG_RSH as well.

```
export BORG_RSH="ssh -i /home/isme/.ssh/id_rsa"
```

I couldn't make it work. Same error about remote host key verification.

I try to generate key for the root user (sigh).
```
$ sudo ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:Ce4+yfsPLR1NAJ9jVoytCsf2QX2O8CHE2NlJKnJFbT4 root@isme-t480s
The key's randomart image is:
+---[RSA 3072]----+
|        .B=Xo.   |
|        .oO=X .  |
|      o.o.BB.=   |
|     ..++=o+E .  |
|      .+So....   |
|     .  .o..     |
|     ...o o      |
|     .+  o       |
|      o+...      |
+----[SHA256]-----+
$ sudo cp /root/.ssh/id_rsa.pub ~/tmp/key
$ cat ~/.ssh/id_rsa.pub >> ~/tmp/key
bash: /home/isme/tmp/key: Permission denied
$ sudo cat ~/.ssh/id_rsa.pub >> ~/tmp/key
bash: /home/isme/tmp/key: Permission denied
$ cat ~/.ssh/id_rsa.pub | sudo tee -a ~/tmp/key
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDaPfP9uWzqflCx/zt1vQ2TtLJB6OQ08w9fG0kkmTOTFA/K56B2V3vo/lFqC1tVto4fHpeFwtlAnEbPJKXArQHHzjgsgiswjQOAtvSG/G/ThPCPXeh2bCXoSh6GPa1sjy6TZQGeYPbJ28ipC4xDUjiZQE0spDxFvE/yDcwMl7rPVlF78izjlo4bO1JGo85oVRfYlCAJ2EH+oNCB0i0/IdswiC5Qawjzi9qKFqn/FrNKhzG2nFtV4JkAjmMWDJ5YOOZFsFkr7RKuaOflBnMYbiyai33kniWBgCDF8aCmpjJ1wxEqwuuTtAxibwx13bD3PtxBm9/RZSfgjw3HK1XT3qHZcsyMXY/OX6m2pne66i0I+71nbXIYToZatPZ0yiyYF2/ENyz6/JrfPGKmY8U5AYaElqU/vgsvfo+8ivDerN546DkxPdovb5E7R1A/rKA3g363BhI3gPR9RAg4lv5ejbncei/QuOoNYDoVS8brQrzX/mysSQvdcLbznlUsPeOz0ms= isme@isme-t480s
$ ls -l ~/tmp/key
-rw-r--r-- 1 root root 1138 Jul 23 13:14 /home/isme/tmp/key
$ sudo chown isme:isme ~/tmp/key
$ less ~/tmp/key
$ scp ~/tmp/key hetzner:.ssh/authorized_keys
key                                                                    100% 1138    27.7KB/s   00:00    
```

Now I can SSH in as root.

Try the borg command again!

```
time \
sudo --preserve-env=BORG_REPO,BORG_RSH \
borg create --verbose --progress --stats \
::full_system_'{now:%Y-%m_%d_%H:%M}' \
/ \
--exclude /dev \
--exclude /proc \
--exclude /sys \
--exclude /run \
--exclude /lost+found \
--exclude /mnt \
--exclude /media \
--exclude /tmp \
--exclude /swapfile \
| tee ~/tmp/borg_create_log.txt
```

Now a new error:

```
Remote: ssh: Could not resolve hostname hetzner: Temporary failure in name resolution
Connection closed by remote host. Is borg working on the server?
```

I need to copy my SSH config to root's folder as well. And edit out the parts it
doesn't need.

```console 
$ sudo cp ~/.ssh/config /root/.ssh/config
$ EDITOR=vim sudoedit /root/.ssh/config
```

Try again.

```
time \
sudo --preserve-env=BORG_REPO,BORG_RSH \
borg create --verbose --progress --stats \
::full_system_'{now:%Y-%m_%d_%H:%M}' \
/ \
--exclude /dev \
--exclude /proc \
--exclude /sys \
--exclude /run \
--exclude /lost+found \
--exclude /mnt \
--exclude /media \
--exclude /tmp \
--exclude /swapfile \
| tee ~/tmp/borg_create_log.txt
```

I give up. This is an error from storage box's custom shell.

```
Got unexpected RPC data format from server:
Command not found. Use 'help' to get a list of available commands.
```

While writing a message to support I figured it out. Now that root has its own key I must not share the BORG_RSH variable.

So the command that works is

```
time \
sudo --preserve-env=BORG_REPO \
borg create --verbose --progress --stats \
::full_system_'{now:%Y-%m_%d_%H:%M}' \
/ \
--exclude /dev \
--exclude /proc \
--exclude /sys \
--exclude /run \
--exclude /lost+found \
--exclude /mnt \
--exclude /media \
--exclude /tmp \
--exclude /swapfile \
| tee ~/tmp/borg_create_log.txt
```

The output I was hoping for.

```
Enter passphrase for key ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad: 
Creating archive at "ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad::full_system_2022-07_23_13:27"
Synchronizing chunks cache...n: Reading filess
Archives: 1, w/ cached Idx: 0, w/ outdated Idx: 0, w/o cached Idx: 1.
Fetching and building archive index for test_archive ...ve
Merging into master chunks index ...
Done.
```

Now to have breakfast!

The borg progress bar I can't show here but it shows the upload rate and each
file name.

In another shell session I can use the `du` command on the storage box to check how mch space is being used.

```
u111111 /home > du -h
 10K	./.ssh
1.4G	./backups/thinkpad/data/0
1.4G	./backups/thinkpad/data
 56K	./backups/thinkpad/lock.exclusive
1.4G	./backups/thinkpad
1.4G	./backups
1.4G	.
```

Complete output:

```
Enter passphrase for key ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad: 
Creating archive at "ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad::full_system_2022-07_23_13:27"
Synchronizing chunks cache...n: Reading filess
Archives: 1, w/ cached Idx: 0, w/ outdated Idx: 0, w/o cached Idx: 1.
Fetching and building archive index for test_archive ...ve
Merging into master chunks index ...
Done.
------------------------------------------------------------------------------  
Repository: ssh://u111111@u111111.your-storagebox.de:23/./backups/thinkpad
Archive name: full_system_2022-07_23_13:27
Archive fingerprint: c296254d42ccf098b5299c9c58451423ed8d791fd0053d2461a4b8026bf89e9a
Time (start): Sat, 2022-07-23 13:27:58
Time (end):   Sat, 2022-07-23 17:20:16
Duration: 3 hours 52 minutes 17.80 seconds
Number of files: 2853698
Utilization of max. archive size: 1%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:              132.32 GB             72.31 GB             52.36 GB
All archives:              132.36 GB             72.35 GB             52.40 GB

                       Unique chunks         Total chunks
Chunk index:                 1298079              2825238
------------------------------------------------------------------------------

real	232m49.617s
user	69m20.011s
sys	13m29.368s
```

To list the archive contents for the /etc folder.

```
borg list --pattern="+etc/*" --pattern="-*" ::full_system_2022-07_23_13:27
```

TODO: to restore 