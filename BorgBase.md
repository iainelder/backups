# BorgBase

## 2023-02-27

### Sign up

Sign up for BorgBase.

I already have a BorgBase login (created 2022-04-27!).

The account with my normal isn't active, and I didn't receive the activation mail or the password reset after 10 minutes, so I created a new account with `+borgbase` email syntax.

No payment details required for sign up. Good for low-risk testing.

## 2023-03-25

### Check email

It's been almost a month since I created the account without doing anything. On 2023-03-20 BorgBase support sent me a friendly email to remind me to set up a backup plan!

### Set up Borg Backups from the CLI

BorgBase first run looks like this:

![](borgbase_first_run.png)

BorgBase has an [API](https://docs.borgbase.com/api/), but it uses GraphQL and has no documentation that I can find. So I'll ignore that for now.

Read [How to Set Up Borg Backups from the Command Line on Linux and macOS](https://docs.borgbase.com/setup/borg/cli/).

Start a local terminal session.

Check the version of borg that I already have installed.

```console
$ borg --version
borg 1.2.4
```

Install Borgmatic.

```console
$ pipx install borgmatic
  installed package borgmatic 1.7.9, installed using Python 3.8.10
  These apps are now globally available
    - borgmatic
    - generate-borgmatic-config
    - upgrade-borgmatic-config
    - validate-borgmatic-config
done! ✨ 🌟 ✨
```

Generate a public-private key pair.

```console
$ ssh-keygen -o -a 100 -t ed25519
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/isme/.ssh/id_ed25519): /home/isme/.ssh/borgbase    
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/isme/.ssh/borgbase
Your public key has been saved in /home/isme/.ssh/borgbase.pub
The key fingerprint is:
SHA256:CVcx7RshYwl9xiCtPhKkngL+81LkEg8TyzUVYaGl2og isme@isme-t480s
The key's randomart image is:
+--[ED25519 256]--+
|      .B*+=*     |
|   . o*  oB.*    |
|  . +=o .o * .   |
|. .*=..o..  o    |
|.E +Bo oS    o   |
| ...o+. o   .    |
|  ..o  . .       |
|   +             |
|    +.           |
+----[SHA256]-----+
```

Copy the public key.

```console
$ cat ~/.ssh/borgbase.pub | copy
```

Go to the BorgBase browser tab.

Click "SSH Keys" from the top menu.

Paste the key into the "Public Key" text area. Call the key "BorgBase".

![](borgbase_add_ssh_key.png)

Click "Add Key".

See the BorgBase key in the key list.

![](borgbase_ssh_key_added.png)

Click Repositories in the top menu.

Click "New Repo".

Use these settings:

* Basics: Repository Name: Thinkpad
* Basics: Repo Region: EU
* Basics: Repo Format: Borg
* Access: Full Access: Thinkpad Key
* Access: Append-Only Access: Leave blank
* Monitoring: Disable Alerts
* Compaction: Enable server-side compaction: disabled
* Advanced: Enable SFTP access: disabled

Click "Add Repository".

Create a new entry in 1Password for the repo called "BorgBase Thinkpad".

Add the repository name to the 1Password entry.

![](borgbase_repository_added_confirmation.png)

Click Close.

See an empty repo in the repo list.

![](borgbase_new_empty_repo.png)

Go to the terminal session.

Copy the repository name from 1Password and paste it at the following `read` prompt.

```bash
read -rs BORG_REPO
export BORG_REPO
```

Initialize the Borg repository.

```console
$ borg init --encryption repokey-blake2
The authenticity of host 'aaaaaaaa.repo.borgbase.com (11.11.11.11)' can't be established.
ECDSA key fingerprint is SHA256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Remote: Warning: Permanently added 'aaaaaaaa.repo.borgbase.com,11.11.11.11' (ECDSA) to the list of known hosts.
Enter new passphrase: 
Enter same passphrase again: 
Do you want your passphrase to be displayed for verification? [yN]: N

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo

See https://borgbackup.readthedocs.io/en/stable/changes.html#pre-1-0-9-manifest-spoofing-vulnerability for details about the security implications.

IMPORTANT: you will need both KEY AND PASSPHRASE to access this repo!
If you used a repokey mode, the key is stored in the repo, but you should back it up separately.
Use "borg key export" to export the key, optionally in printable format.
Write down the passphrase. Store both at safe place(s).
```

Add to the 1Password entry the server's ECDSA key fingerprint and the repo private key.

Choose some test files to add to a test archive. I choose my downloads folder "descargas" in Spanish.

It has 701M of data and has 156 files.

```console
$ du -sh ~/Descargas
701M	/home/isme/Descargas
$ find ~/Descargas | wc --lines
156
```

Create a new test archive and add the test files.

```console
$ borg create ::test-archive-1 ~/Descargas
Enter passphrase for key ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo: 
```

It takes a few seconds to complete.

The guide suggests a hostname-timestamp naming convention for real repos, e.g. `thinkpad-2023-03-25`. Each archive is a versioned snapshot.

The next part of the guide shows how to automate archive creation with Borgmatic. Before doing that, check the BorgBase interface.

Go to the BorgBase browser tab.

See the updated repo status.

![](borgbase_post_test_archive.png)

The Thinkpad repo shows the following changes:

* Usage: 725.23 MB
* Modified: 6 minutes ago

Click the menu symbol in the Thinkpad repo row to open the Event Log.

It shows the following events. `22.22.22.*` is my masked IP address.

|Datetime           |Event |IP        |SSH Key     |Details                    |
|-------------------|------|----------|------------|---------------------------|
|2023-03-25 11:13:53|logout|22.22.22.*|            |Change: 725MB              |
|2023-03-25 11:13:01|login |22.22.22.*|Thinkpad Key|Host: box-eu20.borgbase.com|
|2023-03-25 11:00:23|logout|22.22.22.*|            |Change: 0MB                |
|2023-03-25 10:58:58|login |22.22.22.*|Thinkpad Key|Host: box-eu20.borgbase.com|
|2023-03-25 02:37:17|create|          |            |                           |

Check the bar chart symbol in the row to open Usage.

It shows "Not enough data". Perhaps later it will show statistics over time.

The interface doesn't show the archives. I think BorgBase doesn't have access to those because only I have my password to unencrypt the details.

Go to the terminal session.

Use Borg to list the archives.

```console
$ borg list
Enter passphrase for key ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo: 
test-archive-1                       Sat, 2023-03-25 11:13:15 [a9807aac6c843e1de7c7cb1502bf699df5d77761a4639cd98dacd239d667f6c8]
```

Use Borg to list the files in the archive. Summarize the results with DuckDB. Omit the password prompt from the output.

```bash
borg list --json-lines -- ::test-archive-1 \
| duckdb -markdown -c "
  SELECT
    ROUND(SUM(size) / (1024 * 1024)) AS size_MB,
    COUNT(*) AS count
  FROM read_json_auto('/dev/stdin');
"
```

The size and the count roughly match! This is good enough for now, but later I'll check why there is a slight count difference.

| size_MB | count |
|---------|-------|
| 701.0   | 155   |

## 2023-03-27

### Compare the archive to the source

Why is there a slight count difference between local and archive storage?

This way of counting files has a problem.

```console
$ find ~/Descargas | wc --lines
156
```

One file name is not strictly one line. File names can contain newline characters.

I get a different result when I use null-terminated file names and then count the null bytes.

```console
$ find ~/Descargas -print0 | tr -d -c '\0' | wc -c
155
```

One of the file names has a newline. When printed directly to the terminal the newline is rendered as a question mark!

```console
$ find ~/Descargas -name $'*\n*'
/home/isme/Descargas/folder1/folder2/FILE NAME WITH SPACES?AND A NEW LINE.pdf
```

When piped to another process, the newline is preserved.

```console
$ find ~/Descargas -name $'*\n*' | cat
/home/isme/Descargas/folder1/folder2/FILE NAME WITH SPACES
AND A NEW LINE.pdf
```

Rather than parsing the names to derive a count, I can use the `du --inodes` to count the filesystem entries directly.

```console
$ du --summarize --inodes ~/Descargas | cut --fields 1
155
```

Do the byte counts match exactly? Almost, but not quite.

```console
$ du --summarize --bytes ~/Descargas | cut --fields 1
734618456
```

```console
$  cat /tmp/archive-list.jsonl | jq -n '[inputs | .size] | add'
734573400
```

I'm not sure why that is, but I'm not going to spend more time on it now.

## 2023-03-28

### Set up Borgmatic

Read the [Set up Borgmatic](https://docs.borgbase.com/setup/borg/cli/#step-6--set-up-borgmatic-for-regular-backups) section of the setup guide.

Read the official [Borgmatic documentation](https://torsion.org/borgmatic/).

Read [How to set up backups](https://torsion.org/borgmatic/docs/how-to/set-up-backups/) in the official Borgmatic documentation.

BorgBase and Borgmatic show different ways to install Borgmatic.

* `sudo pip3 install` - global system package
* `pip3 install --user` - user package
* `sudo pip3 install --user` root user package

If you need to back up system files that require privileged access, install as a global system package or as a root user package. If need only to back up user files, install as a normal user.

Use the global system package you have a relatively dedicated system and don't need to worry about library conflicts with other parts of the system Python. This is the simplest way to install Borgmatic but the least flexible.

Use the root user package for better isolation from the system Python's libraries. You may need to configure the `PATH` environment variable or sudo's `secure_path` option to make this work for all users.

Use the user package if you need only to back up user files. This is my use case.

A fourth option that I haven't seen documented in the other sources:

* `pipx install` - user virtualenv

Pipx installs the Python application in its own virtualenv to isolate it from any other Python libraries that I may have installed as a user. This is the method that I will use.

Borgmatic is available in the official Ubuntu 20.04 repository, but it's an old version: `1.5.1` compared to `1.7.10`.

Watch the [Asciinema screencast](https://asciinema.org/a/203761?autoplay=1). It shows how to use `generate-borgmatic-config` to get started. This is the method I will use.

The generator by default would write to `/etc`.

```console
$ generate-borgmatic-config --help
usage: generate-borgmatic-config [-h] [-s SOURCE_FILENAME] [-d DESTINATION_FILENAME] [--overwrite]

Generate a sample borgmatic YAML configuration file.

optional arguments:
  -h, --help            show this help message and exit
  -s SOURCE_FILENAME, --source SOURCE_FILENAME
                        Optional YAML configuration file to merge into the generated configuration,
                        useful for upgrading your configuration
  -d DESTINATION_FILENAME, --destination DESTINATION_FILENAME
                        Destination YAML configuration file, default: /etc/borgmatic/config.yaml
  --overwrite           Whether to overwrite any existing destination file, defaults to false
```

I don't want to configure Borgmatic system-wide. Where else does it look for configuration?

Check `borgmatic --help`:

```text
  -c [CONFIG_PATHS [CONFIG_PATHS ...]], --config [CONFIG_PATHS [CONFIG_PATHS ...]]
                        Configuration filenames or directories, defaults to: /etc/borgmatic/config.yaml
                        /etc/borgmatic.d $HOME/.config/borgmatic/config.yaml $HOME/.config/borgmatic.d
```

Borgmatic checks these paths for config:

* `/etc/borgmatic/config.yaml`
* `/etc/borgmatic.d`
* `$HOME/.config/borgmatic/config.yaml`
* `$HOME/.config/borgmatic.d`

I will use this path for my config: `$HOME/.config/borgmatic/config.yaml`.

Borgmatic automatically creates any missing folders in the path of the destination.

```console
$ generate-borgmatic-config --destination $HOME/.config/borgmatic/config.yaml
Generated a sample configuration file at /home/isme/.config/borgmatic/config.yaml.

This includes all available configuration options with example values. The few
required options are indicated. Please edit the file to suit your needs.

If you ever need help: https://torsion.org/borgmatic/#issues
```

Edit the file to set the following:

* source directories
* repositories
* storage encryption passphrase

I don't like having the password in plaintext in the file. Later I'll look for another way to do this more safely. See the [Borg Security FAQ](https://borgbackup.readthedocs.io/en/stable/faq.html#how-can-i-specify-the-encryption-passphrase-programmatically) for ways to set `BORG_PASSWORD` and `BORG_PASSCOMMAND` including a solution that works with Gnome Keychain.

Save the file and validate it.

```console
$ validate-borgmatic-config
All given configuration files are valid: /home/isme/.config/borgmatic/config.yaml
```

The generated config is mostly comments to explain all the possible options. How does it look without the comments?

Use `yq` to [strip all the comments](https://mikefarah.gitbook.io/yq/operators/comment-operators#remove-strip-all-comments).

```bash
yq '... comments=""' /home/isme/.config/borgmatic/config.yaml
```

The effective configuration looks like this:

```yaml
location:
  source_directories:
    - /home/isme/Descargas
  repositories:
    - path: ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo
      label: BorgBase
storage:
  encryption_passphrase: "..."
retention:
  keep_daily: 7
```

### Create a backup using Borgmatic

Borgmatic can create a repository using its `init` command, but I can skip that becuase I already created the repo using Borg.

Run Borgmatic and start a backup.

```console
$ borgmatic create --verbosity 1 --list --stats
ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo: Creating archive
Creating archive at "ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo::isme-t480s-2023-03-28T13:27:42.529490"
A /home/isme/Descargas/1679609313063.jpeg
Remote: Storage quota: 725.14 MB out of 10.00 GB used.
Remote: Storage quota: 725.14 MB out of 10.00 GB used.
------------------------------------------------------------------------------
Repository: ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo
Archive name: isme-t480s-2023-03-28T13:27:42.529490
Archive fingerprint: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
Time (start): Tue, 2023-03-28 13:27:44
Time (end):   Tue, 2023-03-28 13:27:44
Duration: 0.06 seconds
Number of files: 146
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:              734.57 MB            725.93 MB                639 B
All archives:                1.47 GB              1.45 GB            725.12 MB
                       Unique chunks         Total chunks
Chunk index:                     413                  836
------------------------------------------------------------------------------

summary:
/home/isme/.config/borgmatic/config.yaml: Successfully ran configuration file
```

The backup completes almost instantly. That's because the content of my Download folder has hardly changes. The line beginning `A` may indicate a new file path in the folder. The deduplicated size of the new archive is a mere 639 bytes.

The number of files is 146. This is less than what I counted earlier.

Investigate locally to clarify what's going on.

`du --summarize --inodes` counts 1 inode for each file and each directory including the root.

```console
$ du --summarize --inodes ~/Descargas/
155	/home/isme/Descargas/
```

`tree -a` gives a separate count for all the files and all the directories excluding the root. `146 + 8 = 154`.

```console
$ tree -a ~/Descargas/ | tail -1
8 directories, 146 files
```

Use Borg again to list what is in the new archive to check my understanding.

It still lists 155, which matches `du`.

```console
$ borg list --json-lines -- "::isme-t480s-2023-03-28T13:27:42.529490"  > /tmp/archive.jsonl
Enter passphrase for key ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo: 
$ cat /tmp/archive.jsonl | wc -l
155
```

`tree` and `du` have limited options for filtering what is counted. `find` can filter on almost any attribute of a file. It ocurred to me that I can just print a symbol and use `wc`'s character counting mode.

```console
$ find ! -type d -printf '.' | wc -c
146
$ find -type d -printf '.' | wc -c
9
```

I can find folders in the archive listing like this.

```console
$ cat /tmp/archive.jsonl | jq -n -c '[inputs | select(.type == "d")] | length'
9
```

### Create a backup of my home folder

Reconfigure Borgmatic to backup my entire home folder. It now looks like this:

```yaml
location:
  source_directories:
    - /home/isme
  repositories:
    - path: ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo
      label: BorgBase
storage:
  encryption_passphrase: "..."
retention:
  keep_daily: 7
```

Create a new backup with the following command.

```bash
borgmatic create --verbosity 1 --list --stats
```

This time it takes a long time to run. It prints an `A` line for every file it finds. There are more than one million files in my home folder, so this could take a while.

It fails suddenly with the following error:

```text
The storage quota (10.00 GB) has been exceeded (10.00 GB). Try deleting some archives.
```

There are no stats to tell me how long it took.

### Increase my quota on BorgBase

![](borgbase_10GB.png)

The BorgBase user interface shows that the Thinkpad repo has usage of 10.01 GB.

There is a red dot next to the total usage. A tooltip over the area shows:

> Your plan includes 10 GB with a flexible quota of up to 10 GB.

Click Account.

Click "Add or Extend Plan".

Choose the Small plan, which includes 250GB of storage for $24 per year.

Click Continue.

Complete the billing details and pay.

Get a billing confirmation.

>  Thank you for your order!

Click "Continue to Repos".

There is a green dot next to the total usage. A tooltip over the area shows:

> Your plan includes 250GB with a flexible quota of up to 1 TB.

Now I have a quota big enough to store all my files.

### Create a backup of my home folder again

Create the backup again, this time without the file list.

```bash
borgmatic create --verbosity 1 --stats
```

The output starts like this before pausing. It looks like The incomplete archive was discarded, because it looks like again I'm using just 725 MB of the remote storage cuota.

```text
ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo: Creating archive
Creating archive at "ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo::isme-t480s-2023-03-28T16:13:52.498386"
Remote: Storage quota: 725.14 MB out of 1.00 TB used.
```

This may take a while, so I leave it to run in the background.

### Check backup status

Complete output from Borgmatic.

```text
ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo: Creating archive
Creating archive at "ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo::isme-t480s-2023-03-28T16:13:52.498386"
Remote: Storage quota: 725.14 MB out of 1.00 TB used.
Remote: Storage quota: 18.86 GB out of 1.00 TB used.
Remote: Storage quota: 18.86 GB out of 1.00 TB used.
/home/isme/.aws/boto/cache/e047ea363e408c5ad38c5f366b22f6cbb080361a.json: open: [Errno 13] Permission denied: 'e047ea363e408c5ad38c5f366b22f6cbb080361a.json'
Remote: Storage quota: 21.81 GB out of 1.00 TB used.
------------------------------------------------------------------------------
Repository: ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo
Archive name: isme-t480s-2023-03-28T16:13:52.498386
Archive fingerprint: c5fa9e4e12ad701c4119cc8cb2398bf16519899195ccce449ef64cb24bc2aa0d
Time (start): Tue, 2023-03-28 16:13:54
Time (end):   Tue, 2023-03-28 16:52:18
Duration: 38 minutes 23.82 seconds
Number of files: 857154
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               41.90 GB             24.03 GB             21.06 GB
All archives:               43.37 GB             25.48 GB             21.78 GB
                       Unique chunks         Total chunks
Chunk index:                  643635               861313
------------------------------------------------------------------------------

summary:
/home/isme/.config/borgmatic/config.yaml: Successfully ran configuration file
```

It looks like one of the files failed to copy because of a permissions error. I get the same error when I try to read the file as my normal user. When I use `sudo` it works. I don't need the file anyway so I just delete it locally.

## 2023-03-29

### Automate the backups with a service

Read the the Borgmatic documentation's [Autopilot](https://torsion.org/borgmatic/docs/how-to/set-up-backups/#autopilot) section.

At this point I find the Borgmatic documentation easier to follow than the BorgBase documentation.

It shows how to configure a systemd service to run Borgmatic. It also notes that, depending on the installation method, this part may already be done for me. (Looking forward to upgrading to Ubuntu 22 to see whether that's true!)

Download the sample systemd file.

```bash
cdtemp
wget 'https://projects.torsion.org/borgmatic-collective/borgmatic/raw/branch/master/sample/systemd/borgmatic.service'
wget 'https://projects.torsion.org/borgmatic-collective/borgmatic/raw/branch/master/sample/systemd/borgmatic.timer'
```

Discover [Systemd Configurations Helper for Visual Studio Code](https://github.com/hangxingliu/vscode-systemd). It provides highlighting and documentation for the syntax. This is the first time I've read a systemd service file.

The only part I may want to change is the `Timer` configuration from daily to hourly. For now I will leave it as it is.

```systemd
[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=3h
```

But wait. Can I event run this as a systemd service when it is installed as a user application?

### Learn how to configure a systemd user service

Google `systemd run user application as service`.

Read a variety of solutions:

* [How to run systemd service as specific user and group in Linux](https://www.golinuxcloud.com/run-systemd-service-specific-user-group-linux/)
* [How do I make my systemd service run via specific user and start on boot?](https://askubuntu.com/questions/676007/how-do-i-make-my-systemd-service-run-via-specific-user-and-start-on-boot)
* [Creating User’s Services With systemd](https://www.baeldung.com/linux/systemd-create-user-services)
* [Using systemd to Run Your App](http://perkframework.com/v1/guides/using-systemd-to-run-your-app.html)
* [Run any Executable as Systemd Service in Linux](https://blog.abhinandb.com/run-any-executable-as-systemd-service/)

All introduce the new syntax `WantedBy` but differ on the configured value. Not all of the solutions provide explanations for the value. 

* `default.target`
* `multi-user.target`

Read the [systemd.unit](https://www.freedesktop.org/software/systemd/man/systemd.unit.html) documentation.

> Units can be aliased (have an alternative name), by creating a symlink from the new name to the existing name in one of the unit search paths. For example, \[...\] `default.target` — the default system target started at boot — is commonly aliased to either `multi-user.target` or `graphical.target` to select what is started by default.

Read [Working with systemd targets](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/working-with-systemd-targets_configuring-basic-system-settings) documentation.

> Targets in `systemd` act as synchronization points during the start of your system. Target unit files, which end with the `.target` file extension, represent the `systemd` targets. The purpose of target units is to group together various `systemd` units through a chain of dependencies.
>
> Consider the following examples:
>
> * The `graphical.target` unit for starting a graphical session starts system services such as the GNOME Display Manager (`gdm.service`) or Accounts Service (`accounts-daemon.service`), and also activates the `multi-user.target` unit.
> * Similarly, the `multi-user.target` unit starts other essential system services such as NetworkManager (`NetworkManager.service`) or D-Bus (`dbus.service`) and activates another target unit named `basic.target`.
> While working with `systemd` targets, you can view the default target, change it or change the current target. 

On my computer the default target is `graphical.target`.

```console
$ systemctl get-default
graphical.target
```

The above is also covered in the [systemd.special](https://www.freedesktop.org/software/systemd/man/systemd.special.html) documentation, but perhaps less clearly and harder to find.

Read more:

* [Why do most systemd examples contain WantedBy=multi-user.target?](https://unix.stackexchange.com/questions/506347/why-do-most-systemd-examples-contain-wantedby-multi-user-target)
* [Controlling Targets - runlevels with systemd](https://www.landoflinux.com/linux_runlevels_systemd.html)

Getting historical, the SysV runlevels correspond are mapped for compatibility to some the special targets in systemd.

```console
$ ls -l /lib/systemd/system/runlevel*.target
lrwxrwxrwx 1 root root 15 Mar  2 13:58 /lib/systemd/system/runlevel0.target -> poweroff.target
lrwxrwxrwx 1 root root 13 Mar  2 13:58 /lib/systemd/system/runlevel1.target -> rescue.target
lrwxrwxrwx 1 root root 17 Mar  2 13:58 /lib/systemd/system/runlevel2.target -> multi-user.target
lrwxrwxrwx 1 root root 17 Mar  2 13:58 /lib/systemd/system/runlevel3.target -> multi-user.target
lrwxrwxrwx 1 root root 17 Mar  2 13:58 /lib/systemd/system/runlevel4.target -> multi-user.target
lrwxrwxrwx 1 root root 16 Mar  2 13:58 /lib/systemd/system/runlevel5.target -> graphical.target
lrwxrwxrwx 1 root root 13 Mar  2 13:58 /lib/systemd/system/runlevel6.target -> reboot.target
```

That's enough digging into systemd.

For me it looks like the `default.target` is fine.

Make a copy of the original service file to make changes.

```bash
cp borgmatic.service my.borgmatic.service
```

So I add the following syntax to the `borgmatic.service` file.

```diff
--- borgmatic.service	2023-03-29 10:19:33.602654958 +0200
+++ my.borgmatic.service	2023-03-29 12:41:14.299500482 +0200
@@ -8,2 +8,5 @@
 
+[Install]
+WantedBy=default.target
+
 [Service]
```
There is already an "Install" section in the `.timer` file. I assume I can leave it unchanged.

Many examples include `User` and `Group` keys in the `Service` section, but the Baeldung article says that these are meaningless for a user service. I suppose they are used for a system service that runs as a non-root user.

Yet the Baeldung article still requires the `sudo` command to put the service file in the `/etc/system/`. I don't want to have to do this for a user service.

Which paths does systemctl search? Google `systemctl search path`.

Read [Where do I put my systemd unit file?](https://unix.stackexchange.com/questions/224992/where-do-i-put-my-systemd-unit-file). A lot of helpful notes from someone else in the same situation.

Read `man systemd.unit` to answer the question about the search path.

From the synopsis. I'm not sure what the `...` means.

```text
   System Unit Search Path
       /etc/systemd/system.control/*
       /run/systemd/system.control/*
       /run/systemd/transient/*
       /run/systemd/generator.early/*
       /etc/systemd/system/*
       /etc/systemd/systemd.attached/*
       /run/systemd/system/*
       /run/systemd/systemd.attached/*
       /run/systemd/generator/*
       ...
       /lib/systemd/system/*
       /run/systemd/generator.late/*

   User Unit Search Path
       ~/.config/systemd/user.control/*
       $XDG_RUNTIME_DIR/systemd/user.control/*
       $XDG_RUNTIME_DIR/systemd/transient/*
       $XDG_RUNTIME_DIR/systemd/generator.early/*
       ~/.config/systemd/user/*
       /etc/systemd/user/*
       $XDG_RUNTIME_DIR/systemd/user/*
       /run/systemd/user/*
       $XDG_RUNTIME_DIR/systemd/generator/*
       ~/.local/share/systemd/user/*
       ...
       /usr/lib/systemd/user/*
       $XDG_RUNTIME_DIR/systemd/generator.late/*
```

Use the `unit-paths` command to answer the question from my current configuration.

System:

```console
$ systemd-analyze unit-paths
/etc/systemd/system.control
/run/systemd/system.control
/run/systemd/transient
/run/systemd/generator.early
/etc/systemd/system
/etc/systemd/system.attached
/run/systemd/system
/run/systemd/system.attached
/run/systemd/generator
/usr/local/lib/systemd/system
/lib/systemd/system
/usr/lib/systemd/system
/run/systemd/generator.late
```

User:

```console
$ systemd-analyze --user unit-paths
/home/isme/.config/systemd/user.control
/run/user/1000/systemd/user.control
/run/user/1000/systemd/transient
/run/user/1000/systemd/generator.early
/etc/xdg/xdg-ubuntu/systemd/user
/etc/xdg/systemd/user
/home/isme/.config/systemd/user
/etc/systemd/user
/run/user/1000/systemd/user
/run/systemd/user
/run/user/1000/systemd/generator
/home/isme/.local/share/systemd/user
/usr/share/ubuntu/systemd/user
/usr/local/share/systemd/user
/usr/share/systemd/user
/var/lib/snapd/desktop/systemd/user
/usr/local/lib/systemd/user
/usr/lib/systemd/user
/run/user/1000/systemd/generator.late
```

I can use the following paths without `sudo`. I've added the description from the man page.

* `/home/isme/.config/systemd/user.control`: Persistent and transient configuration created using the dbus API.
* `/home/isme/.config/systemd/user`: User configuration.
* `/home/isme/.local/share/systemd/user`: Units of packages that have been installed in the home directory.

It looks like `/home/isme/.config/systemd/user` is the most appropraite place.

Use this command to find any subdirectories in the search path apart from the `*.wants` directories.

```bash
find $(systemd-analyze --user unit-paths) -mindepth 1 -type d ! -name '*.wants'
```

The only result here is `/usr/lib/systemd/user/vte-spawn-.scope.d`. I will ignore it and put both files in the `/home/isme/.config/systemd/user` directory.

Before making any changes, I count the number of unit files known to systemd.

```console
$ systemd-analyze --user unit-files | grep -o '^ids: ' | wc -l
147
```

I create the user configuration folder and put the files there.

```bash
mkdir -p /home/isme/.config/systemd/user
cp my.borgmatic.service /home/isme/.config/systemd/user/borgmatic.service
cp borgmatic.timer /home/isme/.config/systemd/user/borgmatic.timer
```

I reload the systemd configuration and check the number of known unit files again. There are now two more.

```bash
$ systemctl --user daemon-reload
$ systemd-analyze --user unit-files | grep -o '^ids: ' | wc -l
149
```

I try to start the borgmatic service. It immediately fails and tells me where to get information about that.

```console
$ systemctl --user start borgmatic
Job for borgmatic.service failed because the control process exited with error code.
See "systemctl --user status borgmatic.service" and "journalctl --user -xe" for details.
```

Check the service status:

```text
● borgmatic.service - borgmatic backup
     Loaded: loaded (/home/isme/.config/systemd/user/borgmatic.service; disabled; vendor preset: enabled)
     Active: failed (Result: exit-code) since Wed 2023-03-29 15:59:28 CEST; 54s ago
    Process: 153827 ExecStartPre=/usr/bin/sleep 1m (code=exited, status=218/CAPABILITIES)

Mar 29 15:59:28 isme-t480s systemd[1979]: Starting borgmatic backup...
Mar 29 15:59:28 isme-t480s systemd[153827]: borgmatic.service: ProtectHostname=yes is configured, but UTS namespace setup is prohibited (container manager?), ignoring namespace setup.
Mar 29 15:59:28 isme-t480s systemd[153827]: borgmatic.service: Failed to drop capabilities: Operation not permitted
Mar 29 15:59:28 isme-t480s systemd[153827]: borgmatic.service: Failed at step CAPABILITIES spawning /usr/bin/sleep: Operation not permitted
Mar 29 15:59:28 isme-t480s systemd[1979]: borgmatic.service: Control process exited, code=exited, status=218/CAPABILITIES
Mar 29 15:59:28 isme-t480s systemd[1979]: borgmatic.service: Failed with result 'exit-code'.
Mar 29 15:59:28 isme-t480s systemd[1979]: Failed to start borgmatic backup.
```

Check the journal for a more verbose version of the same:

```text
Mar 29 15:59:28 isme-t480s systemd[1979]: Starting borgmatic backup...
-- Subject: A start job for unit UNIT has begun execution
-- Defined-By: systemd
-- Support: http://www.ubuntu.com/support
-- 
-- A start job for unit UNIT has begun execution.
-- 
-- The job identifier is 967.
Mar 29 15:59:28 isme-t480s systemd[153827]: borgmatic.service: ProtectHostname=yes is configured, but UTS namespace setup is prohibited (container manager?), ignoring namespace setup.
Mar 29 15:59:28 isme-t480s systemd[153827]: borgmatic.service: Failed to drop capabilities: Operation not permitted
Mar 29 15:59:28 isme-t480s systemd[153827]: borgmatic.service: Failed at step CAPABILITIES spawning /usr/bin/sleep: Operation not permitted
-- Subject: Process /usr/bin/sleep could not be executed
-- Defined-By: systemd
-- Support: http://www.ubuntu.com/support
-- 
-- The process /usr/bin/sleep could not be executed and failed.
-- 
-- The error number returned by this process is ERRNO.
Mar 29 15:59:28 isme-t480s systemd[1979]: borgmatic.service: Control process exited, code=exited, status=218/CAPABILITIES
-- Subject: Unit process exited
-- Defined-By: systemd
-- Support: http://www.ubuntu.com/support
-- 
-- An ExecStartPre= process belonging to unit UNIT has exited.
-- 
-- The process' exit code is 'exited' and its exit status is 218.
```

Search Google for `Failed to drop capabilities`.

Find Borgmatic-specific help in a [generic systemd issue](https://github.com/systemd/systemd/issues/4959):

@jzacsh writes:

> or anyone else hitting this -- e.g. in a web search for Failed to drop capabilities: Operation not permitted -- and not finding the error message clear enough on its own, **the tl;dr is you have some overly strict options set in your systemd `.service` file** (drop capabilities in the error message is referring to a systemd option you maybe inherited from somewhere).

@carmenbianca writes:

> For anyone who got here via @jzacsh 's comment regarding borgmatic. Given the [current systemd sample service](https://projects.torsion.org/borgmatic-collective/borgmatic/src/commit/cd234b689d9577a20ca4eec4b2c7a391433ed448/sample/systemd/borgmatic.service), comment out:
>
>     * `LockPersonality`
>     * `PrivateDevices`
>     * `ProtectClock`
>     * `ProtectControlGroups`
>     * `ProtectKernelLogs`
>     * `ProtectKernelModules`
>     * `ProtectKernelTunables`
>     * `CapabilityBoundingSet`

Apply Carmen's changes.

My systemd diff now looks like this:

```diff
--- borgmatic.service	2023-03-29 10:19:33.602654958 +0200
+++ my.borgmatic.service	2023-03-29 16:39:31.156600940 +0200
@@ -8,2 +8,5 @@
 
+[Install]
+WantedBy=default.target
+
 [Service]
@@ -14,3 +17,3 @@
 # the systemd manual: https://www.freedesktop.org/software/systemd/man/systemd.exec.html
-LockPersonality=true
+# LockPersonality=true
 # Certain borgmatic features like Healthchecks integration need MemoryDenyWriteExecute to be off.
@@ -20,8 +23,8 @@
 PrivateTmp=yes
-ProtectClock=yes
-ProtectControlGroups=yes
+# ProtectClock=yes
+# ProtectControlGroups=yes
 ProtectHostname=yes
-ProtectKernelLogs=yes
-ProtectKernelModules=yes
-ProtectKernelTunables=yes
+# ProtectKernelLogs=yes
+# ProtectKernelModules=yes
+# ProtectKernelTunables=yes
 RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
@@ -45,3 +48,3 @@
 # May interfere with running external programs within borgmatic hooks.
-CapabilityBoundingSet=CAP_DAC_READ_SEARCH CAP_NET_RAW
+# CapabilityBoundingSet=CAP_DAC_READ_SEARCH CAP_NET_RAW
```

`PrivateDevices` does not appear in my copy of sample.

Copy my service into the search path again and reload.

```bash
cp my.borgmatic.service /home/isme/.config/systemd/user/borgmatic.service
systemctl --user daemon-reload
```

Try again to start the service. This time the `start` command appears to hang for several seconds, but finally fails with the same error. (The hang is probably caused by the `ExecStartPre=sleep 1m` setting.)

```console
$ systemctl --user start borgmatic
Job for borgmatic.service failed because the control process exited with error code.
See "systemctl --user status borgmatic.service" and "journalctl --user -xe" for details.
```

Status output:

```console
$ systemctl --user status borgmatic
● borgmatic.service - borgmatic backup
     Loaded: loaded (/home/isme/.config/systemd/user/borgmatic.service; disabled; vendor preset: enabled)
     Active: failed (Result: exit-code) since Wed 2023-03-29 16:43:02 CEST; 1min 11s ago
    Process: 163071 ExecStartPre=/usr/bin/sleep 1m (code=exited, status=0/SUCCESS)
    Process: 163285 ExecStart=/usr/bin/systemd-inhibit --who=borgmatic --what=sleep:shutdown --why=Prevent interrupting scheduled backup /root/.local/bin/borgmatic --verbosity -1 --syslog-verbosity 1 (code=exit>
   Main PID: 163285 (code=exited, status=1/FAILURE)

Mar 29 16:42:02 isme-t480s systemd[1979]: Starting borgmatic backup...
Mar 29 16:42:02 isme-t480s systemd[163071]: borgmatic.service: ProtectHostname=yes is configured, but UTS namespace setup is prohibited (container manager?), ignoring namespace setup.
Mar 29 16:43:02 isme-t480s systemd[163285]: borgmatic.service: ProtectHostname=yes is configured, but UTS namespace setup is prohibited (container manager?), ignoring namespace setup.
Mar 29 16:43:02 isme-t480s systemd-inhibit[163286]: Failed to execute : Permission denied
Mar 29 16:43:02 isme-t480s systemd-inhibit[163285]: /root/.local/bin/borgmatic failed with exit status 1.
Mar 29 16:43:02 isme-t480s systemd[1979]: borgmatic.service: Main process exited, code=exited, status=1/FAILURE
Mar 29 16:43:02 isme-t480s systemd[1979]: borgmatic.service: Failed with result 'exit-code'.
Mar 29 16:43:02 isme-t480s systemd[1979]: Failed to start borgmatic backup.
```

It's trying to execute a file in the root user's home folder that doesn't exist.

```console
$ sudo stat /root/.local/bin/borgmatic
stat: cannot stat '/root/.local/bin/borgmatic': No such file or directory
```

The `ExecStart` key contains the path. The idea of the whole command is to avoid interrupting a backup in progress with a sleep or a shutdown.

```systemd
ExecStart=systemd-inhibit --who="borgmatic" --what="sleep:shutdown" --why="Prevent interrupting scheduled backup" /root/.local/bin/borgmatic --verbosity -1 --syslog-verbosity 1
```

I don't need that extra robustness yet. I replace the command with the one I used earlier.

```systemd
ExecStart=borgmatic create --verbosity 1 --stats
```

Now the service diff looks like this:

```diff
--- borgmatic.service	2023-03-29 10:19:33.602654958 +0200
+++ my.borgmatic.service	2023-03-29 16:51:02.088752042 +0200
@@ -8,2 +8,5 @@
 
+[Install]
+WantedBy=default.target
+
 [Service]
@@ -14,3 +17,3 @@
 # the systemd manual: https://www.freedesktop.org/software/systemd/man/systemd.exec.html
-LockPersonality=true
+# LockPersonality=true
 # Certain borgmatic features like Healthchecks integration need MemoryDenyWriteExecute to be off.
@@ -20,8 +23,8 @@
 PrivateTmp=yes
-ProtectClock=yes
-ProtectControlGroups=yes
+# ProtectClock=yes
+# ProtectControlGroups=yes
 ProtectHostname=yes
-ProtectKernelLogs=yes
-ProtectKernelModules=yes
-ProtectKernelTunables=yes
+# ProtectKernelLogs=yes
+# ProtectKernelModules=yes
+# ProtectKernelTunables=yes
 RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
@@ -45,3 +48,3 @@
 # May interfere with running external programs within borgmatic hooks.
-CapabilityBoundingSet=CAP_DAC_READ_SEARCH CAP_NET_RAW
+# CapabilityBoundingSet=CAP_DAC_READ_SEARCH CAP_NET_RAW
 
@@ -62,2 +65,2 @@
 ExecStartPre=sleep 1m
-ExecStart=systemd-inhibit --who="borgmatic" --what="sleep:shutdown" --why="Prevent interrupting scheduled backup" /root/.local/bin/borgmatic --verbosity -1 --syslog-verbosity 1
+ExecStart=borgmatic create --verbosity 1 --stats
```

Copy my service into the search path again and reload.

```bash
cp my.borgmatic.service /home/isme/.config/systemd/user/borgmatic.service
systemctl --user daemon-reload
```

Try again to start the service. This time the `start` command fails with a new error.

```console
$ systemctl --user start borgmatic
Failed to start borgmatic.service: Unit borgmatic.service has a bad unit file setting.
See user logs and 'systemctl --user status borgmatic.service' for details.
```

After a process of trial and error using versions of `borgmatic --help`, I find that I need to specify the absolute path. The diff now looks like this.

```diff
--- borgmatic.service	2023-03-29 10:19:33.602654958 +0200
+++ my.borgmatic.service	2023-03-29 17:11:16.195078920 +0200
@@ -8,2 +8,5 @@
 
+[Install]
+WantedBy=default.target
+
 [Service]
@@ -14,3 +17,3 @@
 # the systemd manual: https://www.freedesktop.org/software/systemd/man/systemd.exec.html
-LockPersonality=true
+# LockPersonality=true
 # Certain borgmatic features like Healthchecks integration need MemoryDenyWriteExecute to be off.
@@ -20,8 +23,3 @@
 PrivateTmp=yes
-ProtectClock=yes
-ProtectControlGroups=yes
 ProtectHostname=yes
-ProtectKernelLogs=yes
-ProtectKernelModules=yes
-ProtectKernelTunables=yes
 RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
@@ -44,5 +42,2 @@
 
-# May interfere with running external programs within borgmatic hooks.
-CapabilityBoundingSet=CAP_DAC_READ_SEARCH CAP_NET_RAW
-
 # Lower CPU and I/O priority.
@@ -59,5 +54,2 @@
 
-# Delay start to prevent backups running during boot. Note that systemd-inhibit requires dbus and
-# dbus-user-session to be installed.
-ExecStartPre=sleep 1m
-ExecStart=systemd-inhibit --who="borgmatic" --what="sleep:shutdown" --why="Prevent interrupting scheduled backup" /root/.local/bin/borgmatic --verbosity -1 --syslog-verbosity 1
+ExecStart=/home/isme/.local/bin/borgmatic create --verbosity 1 --stats
```

Copy the files and restart the daemon.

Try again to start the service. This time the start command hangs.

```console
$ systemctl --user start borgmatic
```

Check the status. Now it looks like the backup is running!

```
● borgmatic.service - borgmatic backup
     Loaded: loaded (/home/isme/.config/systemd/user/borgmatic.service; disabled; vendor preset: enabled)
     Active: activating (start) since Wed 2023-03-29 17:13:52 CEST; 35s ago
   Main PID: 170586 (borgmatic)
     CGroup: /user.slice/user-1000.slice/user@1000.service/borgmatic.service
             ├─170586 /home/isme/.local/pipx/venvs/borgmatic/bin/python /home/isme/.local/bin/borgmatic create --verbosity 1 --stats
             ├─170591 borg create ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo::{hostname}-{now:%Y-%m-%dT%H:%M:%S.%f} /home/isme --info --stats
             ├─170592 borg create ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo::{hostname}-{now:%Y-%m-%dT%H:%M:%S.%f} /home/isme --info --stats
             └─170594 ssh aaaaaaaa@aaaaaaaa.repo.borgbase.com borg serve --info

Mar 29 17:13:52 isme-t480s systemd[1979]: Starting borgmatic backup...
Mar 29 17:13:52 isme-t480s systemd[170586]: borgmatic.service: ProtectHostname=yes is configured, but UTS namespace setup is prohibited (container manager?), ignoring namespace setup.
Mar 29 17:13:53 isme-t480s borgmatic[170586]: ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo: Creating archive
Mar 29 17:13:56 isme-t480s borgmatic[170586]: Creating archive at "ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo::isme-t480s-2023-03-29T17:13:54.104058"
Mar 29 17:13:56 isme-t480s borgmatic[170586]: ANSWER Creating archive at "ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo::isme-t480s-2023-03-29T17:13:54.104058"
Mar 29 17:14:03 isme-t480s borgmatic[170586]: Remote: Storage quota: 21.81 GB out of 1.00 TB used.
Mar 29 17:14:03 isme-t480s borgmatic[170586]: ANSWER Remote: Storage quota: 21.81 GB out of 1.00 TB used.
```

But it's no good if it blocks my terminal while it runs. It's supposed to run in the background.

I cancel the command in my terminal and check the running process. The `borgmatic command is still running in the background.

```console
$ pgrep -f borgmatic | xargs ps -fwwp
UID          PID    PPID  C STIME TTY          TIME CMD
isme      170586    1979  0 17:13 ?        00:00:00 /home/isme/.local/pipx/venvs/borgmatic/bin/python /home/isme/.local/bin/borgmatic create --verbosity 1 --stats
```

After a few mintes I hear the laptop fan turn off and I check to see that it has completed a backup.

Use this command to find just the output lines.
```bash
journalctl --user --since "2023-03-29 17:00:00" | grep ' borgmatic\[' | grep -v 'ANSWER'
```

```log
Mar 29 17:13:53 isme-t480s borgmatic[170586]: ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo: Creating archive
Mar 29 17:13:56 isme-t480s borgmatic[170586]: Creating archive at "ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo::isme-t480s-2023-03-29T17:13:54.104058"
Mar 29 17:14:03 isme-t480s borgmatic[170586]: Remote: Storage quota: 21.81 GB out of 1.00 TB used.
Mar 29 17:19:34 isme-t480s borgmatic[170586]: Remote: Storage quota: 23.59 GB out of 1.00 TB used.
Mar 29 17:19:42 isme-t480s borgmatic[170586]: ------------------------------------------------------------------------------
Mar 29 17:19:42 isme-t480s borgmatic[170586]: Repository: ssh://aaaaaaaa@aaaaaaaa.repo.borgbase.com/./repo
Mar 29 17:19:42 isme-t480s borgmatic[170586]: Archive name: isme-t480s-2023-03-29T17:13:54.104058
Mar 29 17:19:42 isme-t480s borgmatic[170586]: Archive fingerprint: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
Mar 29 17:19:42 isme-t480s borgmatic[170586]: Time (start): Wed, 2023-03-29 17:13:56
Mar 29 17:19:42 isme-t480s borgmatic[170586]: Time (end):   Wed, 2023-03-29 17:19:34
Mar 29 17:19:42 isme-t480s borgmatic[170586]: Duration: 5 minutes 38.09 seconds
Mar 29 17:19:42 isme-t480s borgmatic[170586]: Number of files: 844180
Mar 29 17:19:42 isme-t480s borgmatic[170586]: Utilization of max. archive size: 0%
Mar 29 17:19:42 isme-t480s borgmatic[170586]: ------------------------------------------------------------------------------
Mar 29 17:19:42 isme-t480s borgmatic[170586]:                        Original size      Compressed size    Deduplicated size
Mar 29 17:19:42 isme-t480s borgmatic[170586]: This archive:               41.74 GB             23.92 GB              1.78 GB
Mar 29 17:19:42 isme-t480s borgmatic[170586]: All archives:               85.11 GB             49.39 GB             23.56 GB
Mar 29 17:19:42 isme-t480s borgmatic[170586]:                        Unique chunks         Total chunks
Mar 29 17:19:42 isme-t480s borgmatic[170586]: Chunk index:                  667087              1708836
Mar 29 17:19:42 isme-t480s borgmatic[170586]: ------------------------------------------------------------------------------
Mar 29 17:19:42 isme-t480s borgmatic[170586]: summary:
Mar 29 17:19:42 isme-t480s borgmatic[170586]: /home/isme/.config/borgmatic/config.yaml: Successfully ran configuration file
```

## 2023-03-30

### Learn about systemd service types

See [Learn about systemd service types](systemd.md).

### Fix the Borgmatic user service

The most important change is to set the service type to the recommended defualt of `simple`. This should allow the `systemctl start` command to return quickly and allow the service status to be reported properly.

The service file is now greatly simplified by deleting all the stuff that was only relevant for restricting what the service could do as the root user.

See Appendix for the complete diff.

Test the new service and time how long `systemctl start` takes to return. This time it returns quickly.

```console
$ time systemctl --user start borgmatic

real	0m0.011s
user	0m0.000s
sys	0m0.005s
```

The execution was skipped! The journal doesn't say why, but I suspect the `ConditionACPower=true` setting because the laptop is unplugged.

```console
$ journalctl --user --unit=borgmatic | tail -1
Mar 30 21:57:56 isme-t480s systemd[1979]: Condition check resulted in borgmatic backup being skipped.
```

I comment out `ConditionACPower=true` and try again.

It starts quickly.

```console
$ time systemctl --user start borgmatic

real	0m0.087s
user	0m0.003s
sys	0m0.001s
```

The fan starts blowing. Something is running.

The status shows that the service is `active (running)`.

```console
● borgmatic.service - borgmatic backup
     Loaded: loaded (/home/isme/.config/systemd/user/borgmatic.service; disabled; vendor preset: enabled)
     Active: active (running) since Thu 2023-03-30 22:11:37 CEST; 53s ago
   Main PID: 469774 (borgmatic)
     CGroup: /user.slice/user-1000.slice/user@1000.service/borgmatic.service
             ├─469774 /home/isme/.local/pipx/venvs/borgmatic/bin/python /home/isme/.local/bin/borgmatic create --verbosity 1 --stats
             ├─469779 borg create ssh://jv6dpxwh@jv6dpxwh.repo.borgbase.com/./repo::{hostname}-{now:%Y-%m-%dT%H:%M:%S.%f} /home/isme --info --stats
             ├─469780 borg create ssh://jv6dpxwh@jv6dpxwh.repo.borgbase.com/./repo::{hostname}-{now:%Y-%m-%dT%H:%M:%S.%f} /home/isme --info --stats
             └─469782 ssh jv6dpxwh@jv6dpxwh.repo.borgbase.com borg serve --info

Mar 30 22:11:37 isme-t480s systemd[1979]: Started borgmatic backup.
Mar 30 22:11:38 isme-t480s borgmatic[469774]: ssh://jv6dpxwh@jv6dpxwh.repo.borgbase.com/./repo: Creating archive
Mar 30 22:11:40 isme-t480s borgmatic[469774]: Creating archive at "ssh://jv6dpxwh@jv6dpxwh.repo.borgbase.com/./repo::isme-t480s-2023-03-30T22:11:39.025192"
Mar 30 22:11:40 isme-t480s borgmatic[469774]: ANSWER Creating archive at "ssh://jv6dpxwh@jv6dpxwh.repo.borgbase.com/./repo::isme-t480s-2023-03-30T22:11:39.025192"
Mar 30 22:11:48 isme-t480s borgmatic[469774]: Remote: Storage quota: 24.23 GB out of 1.00 TB used.
Mar 30 22:11:48 isme-t480s borgmatic[469774]: ANSWER Remote: Storage quota: 24.23 GB out of 1.00 TB used.
```

Eventually the backup is created successfully.

So now the service behaves properly. How do I schedule it to run hourly and automatically whenever the computer is on?

### Appendix

```diff
--- /home/isme/tmp/tmp.2023-03-29.OnrXaPxE/borgmatic.service	2023-03-29 10:19:33.602654958 +0200
+++ /home/isme/.config/systemd/user/borgmatic.service	2023-03-30 21:50:07.761828069 +0200
@@ -8,40 +8,7 @@
 
-[Service]
-Type=oneshot
-
-# Security settings for systemd running as root, optional but recommended to improve security. You
-# can disable individual settings if they cause problems for your use case. For more details, see
-# the systemd manual: https://www.freedesktop.org/software/systemd/man/systemd.exec.html
-LockPersonality=true
-# Certain borgmatic features like Healthchecks integration need MemoryDenyWriteExecute to be off.
-# But you can try setting it to "yes" for improved security if you don't use those features.
-MemoryDenyWriteExecute=no
-NoNewPrivileges=yes
-PrivateTmp=yes
-ProtectClock=yes
-ProtectControlGroups=yes
-ProtectHostname=yes
-ProtectKernelLogs=yes
-ProtectKernelModules=yes
-ProtectKernelTunables=yes
-RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
-RestrictNamespaces=yes
-RestrictRealtime=yes
-RestrictSUIDSGID=yes
-SystemCallArchitectures=native
-SystemCallFilter=@system-service
-SystemCallErrorNumber=EPERM
-# To restrict write access further, change "ProtectSystem" to "strict" and uncomment
-# "ReadWritePaths", "ReadOnlyPaths", "ProtectHome", and "BindPaths". Then add any local repository
-# paths to the list of "ReadWritePaths" and local backup source paths to "ReadOnlyPaths". This
-# leaves most of the filesystem read-only to borgmatic.
-ProtectSystem=full
-# ReadWritePaths=-/mnt/my_backup_drive
-# ReadOnlyPaths=-/var/lib/my_backup_source
-# This will mount a tmpfs on top of /root and pass through needed paths
-# ProtectHome=tmpfs
-# BindPaths=-/root/.cache/borg -/root/.config/borg -/root/.borgmatic
+[Install]
+WantedBy=default.target
 
-# May interfere with running external programs within borgmatic hooks.
-CapabilityBoundingSet=CAP_DAC_READ_SEARCH CAP_NET_RAW
+[Service]
+Type=simple
 
@@ -59,5 +26,2 @@
 
-# Delay start to prevent backups running during boot. Note that systemd-inhibit requires dbus and
-# dbus-user-session to be installed.
-ExecStartPre=sleep 1m
-ExecStart=systemd-inhibit --who="borgmatic" --what="sleep:shutdown" --why="Prevent interrupting scheduled backup" /root/.local/bin/borgmatic --verbosity -1 --syslog-verbosity 1
+ExecStart=/home/isme/.local/bin/borgmatic create --verbosity 1 --stats
```

## 2023-04-05

### Run the Borgmatic backup every hour

I set up a [systemd workshop](systemd.md) to learn how to configure a service that runs every so often, either on a calendar-based schedule or relative to boot time.

Now I add simple service and timer files to this repo and copy them to the user service folder.

Reloading the daemon makes the unit files visible but doesn't start the timer.

```console
$ cp --verbose borgmatic/* ~/.config/systemd/user/
'borgmatic/borgmatic.service' -> '/home/isme/.config/systemd/user/borgmatic.service'
'borgmatic/borgmatic.timer' -> '/home/isme/.config/systemd/user/borgmatic.timer'
$ systemctl --user daemon-reload 
$ systemctl --user list-timers --all
NEXT                         LEFT     LAST                         PASSED  UNIT        ACTIVATES    
Wed 2023-04-05 21:24:51 CEST 42s left Wed 2023-04-05 21:23:51 CEST 17s ago dummy.timer dummy.service

1 timers listed.
$ systemctl --user list-timers 
NEXT                         LEFT     LAST                         PASSED  UNIT        ACTIVATES    
Wed 2023-04-05 21:24:51 CEST 31s left Wed 2023-04-05 21:23:51 CEST 28s ago dummy.timer dummy.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
$ systemctl --user list-units-files 'borgmatic.*'
Unknown operation list-units-files.
$ systemctl --user list-unit-files 'borgmatic.*'
UNIT FILE         STATE    VENDOR PRESET
borgmatic.service disabled enabled      
borgmatic.timer   disabled enabled      

2 unit files listed.
```

To start the timer, use the `start` command on the timer. (In the workshop with the dummy service, I had to start the unit itself without `.timer`. I don't understand the difference.)

```console
$ systemctl --user start borgmatic.timer
$ systemctl --user list-timers 'borgmatic'
NEXT LEFT LAST                         PASSED       UNIT            ACTIVATES        
n/a  n/a  Wed 2023-04-05 21:28:58 CEST 2min 55s ago borgmatic.timer borgmatic.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
```

The backup completes. For some reason all of the output lines are duplicated with an "ANSWER" prefix. Omit these.

```consoel
$ journalctl --user --boot --output=cat --unit borgmatic | grep -v ANSWER
/home/isme/.config/systemd/user/borgmatic.service:9: Executable "borgmatic" not found in path "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
borgmatic.service: Unit configuration has fatal error, unit will not be started.
Started Borgmatic backup.
ssh://jv6dpxwh@jv6dpxwh.repo.borgbase.com/./repo: Creating archive
Creating archive at "ssh://jv6dpxwh@jv6dpxwh.repo.borgbase.com/./repo::isme-t480s-2023-04-05T21:28:59.943241"
Remote: Storage quota: 25.82 GB out of 1.00 TB used.
Remote: Storage quota: 26.75 GB out of 1.00 TB used.
------------------------------------------------------------------------------
Repository: ssh://jv6dpxwh@jv6dpxwh.repo.borgbase.com/./repo
Archive name: isme-t480s-2023-04-05T21:28:59.943241
Archive fingerprint: 36b2d17297f3a5a3204be064046537f90b8afd39dab22c73f7150c4dc147dc51
Time (start): Wed, 2023-04-05 21:29:02
Time (end):   Wed, 2023-04-05 21:33:08
Duration: 4 minutes 6.51 seconds
Number of files: 860687
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               42.24 GB             24.09 GB            928.74 MB
All archives:              253.22 GB            145.56 GB             26.72 GB
                       Unique chunks         Total chunks
Chunk index:                  727552              5141489
------------------------------------------------------------------------------
summary:
/home/isme/.config/borgmatic/config.yaml: Successfully ran configuration file
borgmatic.service: Succeeded.
```

The service is schedule to run again 1 hour after it started.

```console
$ systemctl --user list-timers 'borgmatic'
NEXT                         LEFT       LAST                         PASSED   UNIT            ACTIVATES        
Wed 2023-04-05 22:28:58 CEST 51min left Wed 2023-04-05 21:28:58 CEST 8min ago borgmatic.timer borgmatic.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
```

Wait an hour to see whether it really does run again.

### Find folders to exclude from the backup

There are a lot of cache folders in the home folder that can be excluded from the backup without losing anything very important.

Use the visual Disk Usage Analyzer to find them easily.

Incomplete list of paths in my home folder to exclude:

* `.cache`
* `.config/google-chrome/Default/Service Worker/CacheStorage`
* `.config/Slack/Service Worker/CacheStorage`
* `.config/Cache`
* `.config/Code/Cache`

There are over 7000 folders with "cache" in the name. It could be a long list!

```console
$ find ~ -type d -ipath '*cache*' -prune -printf '.' | wc -c
7090
```

Almost all of the folders are `__pycache__` folders that can be matched with a single pattern.

```console
$ find ~ -type d -name '__pycache__' -prune -printf '.' | wc -c
6818
```

The top 10 biggest cache folders.

```console
$ find ~ -type d -ipath '*cache*' ! -name '__pycache__' -prune -print0 | du -s --files0-from - | sort -g -r | head -n 10
8651212	/home/isme/.cache
1639180	/home/isme/.config/google-chrome/Default/Service Worker/CacheStorage
1063456	/home/isme/.config/Slack/Service Worker/CacheStorage
701612	/home/isme/.npm/_cacache
431852	/home/isme/.mozilla/firefox/0314ys9a.default-release/storage/default/https+++app.slack.com/cache
365736	/home/isme/.terraform.d/plugin-cache
279484	/home/isme/.config/Microsoft/Microsoft Teams/Code Cache
270628	/home/isme/.config/Slack/Cache
252832	/home/isme/.config/Code/Cache
210048	/home/isme/Repos/.../node_modules/.cache
```

## TODO

TODO: Run the borgmatic backup every hour.

TODO: Find a way to avoid answering the password prompt for every Borg invocation.

TODO: Find a way to avoid embedding the password in the Borgmatic configuration.

TODO: Confirm my understanding of why the BorgBase website doesn't show the archives in my repo.
