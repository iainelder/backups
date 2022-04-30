# BorgBackup

Following the
[installation instructions](https://borgbackup.readthedocs.io/en/stable/installation.html).

Latest release in apt repo:
[1.1.15](https://github.com/borgbackup/borg/releases/tag/1.1.15), from
2020-12-25.

Latest release on Github:
[1.2.0](https://github.com/borgbackup/borg/releases/tag/1.2.0), released
2022-02-22.

It's published as a Python package and installation via pip is documented. So I'll try to install it with pipx.

```
pipx install borgbackup
```

There was an error:

```
$ pipx install borgbackup
Fatal error from pip prevented installation. Full pip output in file:
    /home/isme/.local/pipx/logs/cmd_2022-04-22_16.54.50_pip_errors.log

pip seemed to fail to build package:
    borgbackup

Some possibly relevant errors from pip install:
    error: subprocess-exited-with-error
    Exception: Could not find OpenSSL lib/headers, please set BORG_OPENSSL_PREFIX
    error: metadata-generation-failed

Error installing borgbackup.
```

There is also a binary available. I'll try that now.

> Note that the binary uses /tmp to unpack Borg with all dependencies. It will
> fail if /tmp has not enough free space or is mounted with the noexec option.
> You can change the temporary directory by setting the TEMP environment
> variable before running Borg.

How is /tmp mounted? Use findmnt to list mounted file systems (volumes in Ubuntu
parlance).

```text
$ findmnt /tmp
$ findmnt /
TARGET SOURCE         FSTYPE OPTIONS
/      /dev/nvme0n1p3 ext4   rw,relatime,errors=remount-ro
```

So /tmp is part of the main file system mount. Is that going to cause a problem?
I'll assume not.

How do I back up the whole of /?

```
$ borg init --encryption=repokey /media/isme/Samsung_T5/backup
Enter new passphrase: 
Enter same passphrase again: 
Do you want your passphrase to be displayed for verification? [yN]: 
Failed to securely erase old repository config file (hardlinks not supported>). Old repokey data, if any, might persist on physical storage.

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam /media/isme/Samsung_T5/backup

See https://borgbackup.readthedocs.io/en/stable/changes.html#pre-1-0-9-manifest-spoofing-vulnerability for details about the security implications.

IMPORTANT: you will need both KEY AND PASSPHRASE to access this repo!
If you used a repokey mode, the key is stored in the repo, but you should back it up separately.
Use "borg key export" to export the key, optionally in printable format.
Write down the passphrase. Store both at safe place(s).

List the empty repository:

```
$ borg list /media/isme/Samsung_T5/backup
Enter passphrase for key /media/isme/Samsung_T5/backup: 
```

Backup repos to an archive called Repos:

```text
$ borg create --stats /media/isme/Samsung_T5/backup::Repos ~/Repos
Enter passphrase for key /media/isme/Samsung_T5/backup: 
------------------------------------------------------------------------------
Repository: /media/isme/Samsung_T5/backup
Archive name: Repos
Archive fingerprint: 295f261e02744bfae9a149c311d288aef6313aa593c9f71acf8ef32094caf63b
Time (start): Sun, 2022-04-24 18:07:07
Time (end):   Sun, 2022-04-24 18:09:32
Duration: 2 minutes 24.77 seconds
Number of files: 111832
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:                6.31 GB              3.71 GB              3.06 GB
All archives:                6.31 GB              3.71 GB              3.06 GB

                       Unique chunks         Total chunks
Chunk index:                   74215               112921
------------------------------------------------------------------------------
```

```text
$ tree /media/isme/Samsung_T5/backup
/media/isme/Samsung_T5/backup
├── config
├── data
│   └── 0
│       ├── 0
│       ├── 1
│       ├── 10
│       ├── 2
│       ├── 3
│       ├── 4
│       ├── 5
│       ├── 6
│       ├── 7
│       ├── 8
│       └── 9
├── hints.10
├── index.10
├── integrity.10
├── nonce
└── README

2 directories, 17 files
```

Next steps:

* [try to restore a file locally](borg-try-to-restore-a-file-locally.md)
* try to restore a file on a different computer (local VM? EC2 instance?)
* try to backup full filesystem (see below)
* try to restore full filesystem

See FAQ on
[backing up the root partition](https://borgbackup.readthedocs.io/en/stable/faq.html#can-i-backup-my-root-partition-with-borg):

> Can I backup my root partition (/) with Borg?

> Backing up your entire root partition works just fine, but remember to exclude
> directories that make no sense to backup, such as /dev, /proc, /sys, /tmp and
> /run, and to use `--one-file-system` if you only want to backup the root
> partition (and not any mounted devices e.g.).

