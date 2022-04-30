# Borg: Try to restore t o a different computer

First I will try to restore to a local VM. This may help when testing the
upgrade to Ubuntu 22.

But how do I set up a local VM? It's been a while.

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

So now to test the restore I can try the following:

* Mount the backup folder as read-only from the external hard drive
* Install version 1.2.0 of borg backup in the VM
* Use borg backup to restore a file from the Repos backup repo
