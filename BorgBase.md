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
Enter passphrase for key ssh://jv6dpxwh@jv6dpxwh.repo.borgbase.com/./repo: 
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
Enter passphrase for key ssh://jv6dpxwh@jv6dpxwh.repo.borgbase.com/./repo: 
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

## TODO

TODO: Check why there is a slight count difference between local and archive storage.

TODO: Find a way to avoid answering the password prompt for every Borg invocation.

TODO: Complete the setup guide to automate the archives with Borgmatic.

TODO: Confirm my understanding of why the BorgBase website doesn't show the archives in my repo.