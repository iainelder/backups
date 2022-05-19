# Borg: Try to restore to a different computer

First I will try to restore to a local VM. This may help when testing the
upgrade to Ubuntu 22.

But how do I set up a local VM? It's been a while.

## Setting up a local VM

I use VirtualBox and Vagrant to manage my local VMs.

```
$ VBoxManage --version
6.1.34r150636

$ vagrant --version
Vagrant 2.2.19
```

This is the official Ubuntu 20.04 LTS build Vagrant box for VirtualBox.

https://app.vagrantup.com/ubuntu/boxes/focal64

Use `vagrant box add ubuntu/focal64` to add the box.

From the new box instructions:

```
cdtemp
vagrant init ubuntu/focal64
vagrant up
```

I see a warning about synced folders. I think I can ignore it, but I'll make a note anyway.

```
Vagrant is currently configured to create VirtualBox synced folders with
the `SharedFoldersEnableSymlinksCreate` option enabled. If the Vagrant
guest is not trusted, you may want to disable this option. For more
information on this option, please refer to the VirtualBox manual:

  https://www.virtualbox.org/manual/ch04.html#sharedfolders

This option can be disabled globally with an environment variable:

  VAGRANT_DISABLE_VBOXSYMLINKCREATE=1

or on a per folder basis within the Vagrantfile:

  config.vm.synced_folder '/host/path', '/guest/path', SharedFoldersEnableSymlinksCreate: false
```

I can ssh into the box!

```
$ vagrant ssh
Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.4.0-109-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Sat Apr 30 12:33:06 UTC 2022

  System load:  0.79              Processes:               122
  Usage of /:   3.5% of 38.71GB   Users logged in:         0
  Memory usage: 21%               IPv4 address for enp0s3: 10.0.2.15
  Swap usage:   0%


1 update can be applied immediately.
To see these additional updates run: apt list --upgradable


vagrant@ubuntu-focal:~$ 

```

Now how do I mount the file system that contains the backup repo?

I think I can use
[synced folders](https://www.vagrantup.com/docs/synced-folders/basic_usage). I
can maybe use `mount_options` to set the mount to read-only. The documentation
is scant. I think I need to read the documentation on the mount command and pass
each key=value option as a string in an array in the Vagrantfile.

First let's try to mount something from the main filesystem.

```ruby
  # Test mounting backup folder.
  config.vm.synced_folder(
    "/home/isme/Repos/dotfiles",
    "/dotfiles"
  )
```

Use `vagrant reload` to apply the new configuration.

The output shows the mounting.

```text
==> default: Mounting shared folders...
    default: /vagrant => /home/isme/tmp/tmp.2022-04-30.EwSiDmD7
    default: /dotfiles => /home/isme/Repos/dotfiles
```

I can list the external files.

```
vagrant@ubuntu-focal:~$ ls /dotfiles
README.md               bin               programs  test-mitmproxy  test_fuse.bash   ubuntu-20-setup.md
add_bats_assertions.sh  generate_ci.bash  scripts   test.bats       test_local.bash
```

How is it mounted?

```
vagrant@ubuntu-focal:~$ findmnt /dotfiles
TARGET    SOURCE   FSTYPE OPTIONS
/dotfiles dotfiles vboxsf rw,nodev,relatime,iocharset=utf8,uid=1000,gid=1000
```

It's mounted as readable and writable (rw).

```
# VM
vagrant@ubuntu-focal:~$ touch /dotfiles/from_vagrant

# Main
$ ls ~/Repos/dotfiles/from_vagrant
/home/isme/Repos/dotfiles/from_vagrant
```

What do the other options mean?

From `man 5 fstab`:

```
       The fourth field (fs_mntops).
              This field describes the mount options associated with the filesystem.

              It is formatted as a comma-separated list of options.  It contains at least the type  of
              mount  (ro  or  rw), plus any additional options appropriate to the filesystem type (in‐
              cluding performance-tuning options).  For details, see mount(8) or swapon(8).
```

nodev and relatime are documented as FILESYSTEM-INDEPENDENT MOUNT OPTIONS in
`man 8 mount`.

nodev: Do not interpret character or block special devices on the file system.

relatime: Access time is only updated if the previous access time was earlier
than the current modify of change time.

iocharset appears to be a FILESYSTEM-DEPENDENT MOUNT OPTION. vboxsf (VirtualBox
shared folder) is not listed in the stock Ubuntu's mount documentation. The
listed filesystems that support the option appear to use it to set the encoding
of file names. So here file names would be encoded with UTF-8.

uid and gid are also filesystem-dependent. The other filesystems that support
the options appear to use them to set the owner and the group of the files.

So to mount it as read-only I think I need to use Vagrantfile fragment.

```ruby
  # Test mounting backup folder.
  config.vm.synced_folder(
    "/home/isme/Repos/dotfiles",
    "/dotfiles",
    mount_options: ["ro"]
  )
```

Now `vagrant reload` appears to show a warning about the owner and group ID.

```
==> default: Mounting shared folders...
    default: /vagrant => /home/isme/tmp/tmp.2022-04-30.EwSiDmD7
    default: /dotfiles => /home/isme/Repos/dotfiles
==> default: Detected mount owner ID within mount options. (uid: 1000 guestpath: /dotfiles)
==> default: Detected mount group ID within mount options. (gid: 1000 guestpath: /dotfiles)
```

Now the folder is mounted as read only.

```
vagrant@ubuntu-focal:~$ findmnt /dotfiles
TARGET    SOURCE   FSTYPE OPTIONS
/dotfiles dotfiles vboxsf ro,nodev,relatime,iocharset=utf8,uid=1000,gid=1000
```

And so writing is prevented (Nice clear message from touch!).

```
vagrant@ubuntu-focal:~$ touch /dotfiles/by_vagrant
touch: cannot touch '/dotfiles/by_vagrant': Read-only file system
```

## Restoring to a VM

So now to test the restore I can try the following:

* Mount the backup folder as read-only from the external hard drive
* Install version 1.2.0 of borg backup in the VM
* Use borg backup to restore a file from the Repos backup repo

Reminder: The backup folder is `/media/isme/Samsung_T5/backup/`.

Borg doesn't keep a registry of backup locations. That's something you need to
keep track of yourself.

Init a new VM.

```bash
cdtemp
vagrant init ubuntu/focal64
```

Use this Vagrantfile fragment to mount the backup folder as read-only from the
external hard drive.

```ruby
  config.vm.synced_folder(
    "/media/isme/Samsung_T5/backup",
    "/backup",
    mount_options: ["ro"]
  )
```

Launch the VM.

```bash
vagrant up
```

The output shows that the external hard drive backup repo folder was mounted.

```text
==> default: Mounting shared folders...
    default: /backup => /media/isme/Samsung_T5/backup
```

SSH into the VM.

```bash
vagrant ssh
```

The backup folder is readable and not writable.

```console
vagrant@ubuntu-focal:~$ cat /backup/README
This is a Borg Backup repository.
See https://borgbackup.readthedocs.io/
vagrant@ubuntu-focal:~$ touch /backup/write_test
touch: cannot touch '/backup/write_test': Read-only file system
```

Use these commands, adapted from my own
[BorgBackup installation script](https://github.com/iainelder/dotfiles/blob/master/programs/borgbackup/install.bash),
to install the latest version of the tool.

```bash
sudo apt-get -y update

sudo apt-get -y install jq

browser_download_url=$(
  curl -Ss 'https://api.github.com/repos/borgbackup/borg/releases/latest' |
  jq -r '.assets[] | select(.name | test("borg-linux64$")) | .browser_download_url'
)

download_filename=$(
  curl \
  --silent \
  --show-error \
  --url "$browser_download_url" \
  --location \
  --remote-name \
  --write-out '%{filename_effective}'
)

sudo install -T "$download_filename" /usr/local/bin/borg

borg --version
```

The last command prints `borg 1.2.0` so we're ready to test a restore.

Try to list the backup repos in the folder.

```console
vagrant@ubuntu-focal:~$ borg list /backup
Failed to create/acquire the lock /backup/lock.exclusive ([Errno 30] Read-only file system: '/backup/lock.exclusive.f5p5mwal.tmp').
Traceback (most recent call last):
  File "borg/archiver.py", line 5089, in main
  File "borg/archiver.py", line 5020, in run
  File "borg/archiver.py", line 168, in wrapper
  File "borg/repository.py", line 200, in __enter__
  File "borg/repository.py", line 431, in open
  File "borg/locking.py", line 387, in acquire
  File "borg/locking.py", line 115, in __enter__
  File "borg/locking.py", line 137, in acquire
borg.locking.LockFailed: Failed to create/acquire the lock /backup/lock.exclusive ([Errno 30] Read-only file system: '/backup/lock.exclusive.f5p5mwal.tmp').

Platform: Linux ubuntu-focal 5.4.0-109-generic #123-Ubuntu SMP Fri Apr 8 09:10:54 UTC 2022 x86_64
Linux: Unknown Linux  
Borg: 1.2.0  Python: CPython 3.9.10 msgpack: 1.0.3 fuse: llfuse 1.4.1 [pyfuse3,llfuse]
PID: 3188  CWD: /home/vagrant
sys.argv: ['borg', 'list', '/backup']
SSH_ORIGINAL_COMMAND: None
```

It failed because it was unable to acquire a lock on the backup folder! It looks
like borg can't use a read-only backup.

There is an open issue about in Borg's GitHub:
[Allow operations on read-only filesystems (#1035)](https://github.com/borgbackup/borg/issues/1035).

Users of borg use these backup services:

* rsync.net
* Backblaze

zoot suggests a workaround: create a folder in a writable directory to mimic the
backup folder and link all the backup folder's contents in the writable folder.

In zoot's situation the backup is mounted over SSH. My backup is mounted locally
and so the script to set it up can be much simpler.

Assume that `/backup` is already is already mounted as a read-only filesystem.

I create a folder called `./backup` in my writable working directory.

To generate commands to link all the backup folder's contents to the writable
backup folder:

```bash
find /backup  -mindepth 1 -maxdepth 1 -printf '%f\0' \
| xargs -0 -I{} echo ln -s /backup/{} ./backup/{}
```

Output:

```bash
ln -s /backup/README ./backup/README
ln -s /backup/data ./backup/data
ln -s /backup/config ./backup/config
ln -s /backup/nonce ./backup/nonce
ln -s /backup/index.10 ./backup/index.10
ln -s /backup/hints.10 ./backup/hints.10
ln -s /backup/integrity.10 ./backup/integrity.10
```

I execute these commands and now I can list the backup archives from the
read-only filesystem.

```console
vagrant@ubuntu-focal:~$ borg list ./backup
Enter passphrase for key /home/vagrant/backup: 
Repos                                Sun, 2022-04-24 16:07:07 [295f261e02744bfae9a149c311d288aef6313aa593c9f71acf8ef32094caf63b]
```

I will try now to extract the dotfiles README to my working directory.

```bash
borg extract \
--list \
./backup::Repos \
home/isme/Repos/dotfiles/README.md
```

Output:

```text
home/isme/Repos/dotfiles/README.md
```

New files in working folder:

```console
vagrant@ubuntu-focal:~$ tree -p -u -g --du ./home
./home
└── [drwx------ vagrant  vagrant        21142]  isme
    └── [drwx------ vagrant  vagrant        17046]  Repos
        └── [drwx------ vagrant  vagrant        12950]  dotfiles
            └── [-rw-rw-r-- vagrant  vagrant         8854]  README.md

       25238 bytes used in 3 directories, 1 file
```

But a command like `borg check` still fails.

```console
vagrant@ubuntu-focal:~$ borg check ./backup
Local Exception
Traceback (most recent call last):
  File "borg/archiver.py", line 5089, in main
  File "borg/archiver.py", line 5020, in run
  File "borg/archiver.py", line 183, in wrapper
  File "borg/archiver.py", line 342, in do_check
  File "borg/repository.py", line 1013, in check
  File "borg/repository.py", line 332, in save_config
  File "borg/helpers/fs.py", line 194, in secure_erase
OSError: [Errno 30] Read-only file system: '/home/vagrant/backup/config.old'

Platform: Linux ubuntu-focal 5.4.0-109-generic #123-Ubuntu SMP Fri Apr 8 09:10:54 UTC 2022 x86_64
Linux: Unknown Linux  
Borg: 1.2.0  Python: CPython 3.9.10 msgpack: 1.0.3 fuse: llfuse 1.4.1 [pyfuse3,llfuse]
PID: 4112  CWD: /home/vagrant
sys.argv: ['borg', 'check', './backup']
SSH_ORIGINAL_COMMAND: None
```

The simpler solution now is to use `--bypass-lock`.

```console
vagrant@ubuntu-focal:~$ borg list --bypass-lock /backup
Enter passphrase for key /backup: 
Warning: The repository at location /backup was previously located at /home/vagrant/backup
Do you want to continue? [yN] y
Repos                                Sun, 2022-04-24 16:07:07 [295f261e02744bfae9a149c311d288aef6313aa593c9f71acf8ef32094caf63b]
```

Now try to restore everything.

```bash
time borg extract \
--bypass-lock \
--list \
/backup::Repos \
2>&1 \
| tee borg-output.txt
```

It restored 137k files of 6.3G in 105 seconds.

```
real	1m45.934s
user	1m9.999s
sys	0m23.912s

vagrant@ubuntu-focal:~$ wc -l borg-output.txt 
137380 borg-output.txt
vagrant@ubuntu-focal:~$ du -sh /home
du: cannot read directory '/home/ubuntu/.ssh': Permission denied
6.3G	/home
```

One thing to note is that on a different computer the user that restores the
data might be different from the one that created the folder. In this case, the
vagrant user can't read the .ssh folder because it was created by the isme user.

A quick way to work around it is to use `sudo` for the checking operations. The
root user can bypass file permissions.
