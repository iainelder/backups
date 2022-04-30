# Borg: Try to restore a file locally

Now I have a backup of my source code repos. Let's ignore the fact that I can
just clone the code repos to get a new copy of them. Say I want to restore a
README from one of my code repos to my computer. How do I do that?

I need to use precise language here. I'll talk about code repos and backup
repos.

What does my backup repo contain? I can use the `borg list` command to produce
an ls-style listing of the files in the repo. It looks like the files are dated
for when they were last modified when I backed them up.

```
$ borg list /media/isme/Samsung_T5/backup/::Repos
drwxrwxr-x isme   isme          0 Fri, 2022-04-22 12:09:42 home/isme/Repos
drwxrwxr-x isme   isme          0 Fri, 2022-04-22 16:53:13 home/isme/Repos/life-notes
-rw-rw-r-- isme   isme       1295 Tue, 2020-12-29 22:36:02 home/isme/Repos/life-notes/ubuntu-20-setup.md
-rw-rw-r-- isme   isme         61 Sun, 2021-01-24 12:40:28 home/isme/Repos/life-notes/cleaning-products-i-like.md
-rw-rw-r-- isme   isme        336 Mon, 2022-01-24 12:40:38 home/isme/Repos/life-notes/Better note taking
drwxrwxr-x isme   isme          0 Sun, 2022-04-24 17:59:14 home/isme/Repos/life-notes/.git
[...]
```

From `--help`, the default format string for the listing is:

* mode: not explained in help, looks like ls file mode output
* user:6: not explained in help, looks like ls owner user name, minimum with 6 characters
* group:6: as above for group user name
* size: file size in bytes, minimum width 8 characters
* mtime: modification time?
* path: path interpreted as text (might be missing non-text characters, see bpath)
* extra: prepends {source} with " -> " for soft links and " link to " for hard links
* NL: OS dependent line separator

TODO: where do all these unexplained attributes come from?

How do I find a README?

See `borg help patterns`:

```
Shell-style patterns, selector sh:
    This is the default style for --pattern and --patterns-from.
    Like fnmatch patterns these are similar to shell patterns. The difference
    is that the pattern may include **/ for matching zero or more directory
    levels, * for matching zero or more arbitrary characters with the
    exception of any path separator. A leading path separator is always removed.
```

Also note for future:

```
To test your exclusion patterns without performing an actual backup you can
run borg create --list --dry-run ....
```

More notes:

```
    Via --pattern or --patterns-from you can define BOTH inclusion and exclusion
    of files using pattern prefixes + and -. With --exclude and
    --exclude-from ONLY excludes are defined.
```

The most useful part of the help is the patterns examples, which shows how to
use a pattern file. That will be useful for programming a backup.

Try this:

```
$ borg list --pattern="+**/README.md" --pattern="-*" --first=5 /media/isme/Samsung_T5/backup::Repos | head --lines 5
Enter passphrase for key /media/isme/Samsung_T5/backup: 
-rw-rw-r-- isme   isme       8854 Wed, 2021-12-15 16:08:11 home/isme/Repos/dotfiles/README.md
-rw-rw-r-- isme   isme        249 Wed, 2021-04-14 10:44:32 home/isme/Repos/dotfiles/programs/gnucash3/README.md
-rw-rw-r-- isme   isme        261 Wed, 2021-04-14 10:44:32 home/isme/Repos/dotfiles/scripts/profile/private/README.md
-rw-rw-r-- isme   isme       8624 Sat, 2021-09-04 16:22:51 home/isme/Repos/github.com/zcutlip/pyonepassword/README.md
-rw-rw-r-- isme   isme       8764 Thu, 2021-07-01 02:07:33 home/isme/Repos/github.com/binxio/aws-cfn-update/README.md
```

I will try to restore the dotfiles README.

From `borg extract --help`:

```
    Currently, extract always writes into the current working directory ("."),
    so make sure you cd to the right place before calling borg extract.
```

I will make a new temp folder to test the extraction.

```
cdtemp
```

Use the dry-run option first to see what would be extracted.

Neither of the following forms appear to list anything as a dry run.

```bash
borg extract \
--dry-run \
--pattern="+home/isme/Repos/dotfiles/README.md" \
--pattern="-*" \
/media/isme/Samsung_T5/backup::Repos
```

```bash
borg extract \
--dry-run \
/media/isme/Samsung_T5/backup::Repos \
home/isme/Repos/dotfiles/README.md
```

Maybe I need the list option.

```bash
borg extract \
--dry-run \
--list \
--pattern="+home/isme/Repos/dotfiles/README.md" \
--pattern="-*" \
/media/isme/Samsung_T5/backup::Repos
```


```bash
borg extract \
--dry-run \
--list \
/media/isme/Samsung_T5/backup::Repos \
home/isme/Repos/dotfiles/README.md
```


Now each form outputs a single file after the password prompt.

```
Enter passphrase for key /media/isme/Samsung_T5/backup: 
home/isme/Repos/dotfiles/README.md
```

Now remove the dry run to see if it really writes the file. Use the shorter form
for convenience.

```
borg extract \
--list \
/media/isme/Samsung_T5/backup::Repos \
home/isme/Repos/dotfiles/README.md
```

It restores the file and the whole hierarchy above it. The file size of
README.md is the same.

```text
$ tree -p -u -g --du
.
└── [drwx------ isme     isme           25238]  home
    └── [drwx------ isme     isme           21142]  isme
        └── [drwx------ isme     isme           17046]  Repos
            └── [drwx------ isme     isme           12950]  dotfiles
                └── [-rw-rw-r-- isme     isme            8854]  README.md

       29334 bytes used in 4 directories, 1 file
```

Okay, so I can restore a file locally.

What about the entire backup repo?

```
rm -rf *

time borg extract \
--list \
/media/isme/Samsung_T5/backup::Repos \
2>&1 \
| tee ~/tmp/borg-output.txt
```

It restored 137k files of 6.3G in 84 seconds.

```
real	1m23.998s
user	1m1.694s
sys	0m16.659s

$ wc -l ~/tmp/borg-output.txt
137380 /home/isme/tmp/borg-output.txt

$ du -sh
6.3G	.
```
