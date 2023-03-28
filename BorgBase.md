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

## TODO

TODO: Find a way to avoid answering the password prompt for every Borg invocation.

TODO: Find a way to avoid embedding the password in the Borgmatic configuration.

TODO: Confirm my understanding of why the BorgBase website doesn't show the archives in my repo.
