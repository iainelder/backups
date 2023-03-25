# Ubuntu Backup Services

Not having a backup solution is making me anxious. How do I solve this?

## Jim Mendenhall

Jim Mendenhall wrote an article in 2018 with [5 Online Backup Solutions for Ubuntu Linux](https://www.starryhope.com/online-backup-solutions-for-ubuntu-linux/).

* Crashplan: Recommended by the author. [See Pricing and Product Comparison](https://www.crashplan.com/en-us/pricing/). USD 10 per month for unlimited storage for one endpoint. Supports Ubuntu.
* [SpiderOak One](https://crossclave.com/one/)
* [Duplicati](https://github.com/duplicati/duplicati) really looks like a good option for open source
* CloudBerry Backup. Is a backup client, but needs a storage backend. Supports AWS, Azure, and GCP out the box. Linux client costs EUR 36.60.
* Deja Dup + NextCloud ([Missing in Ubuntu 20.04?](https://askubuntu.com/questions/1274236/backups-deja-dup-is-missing-nextcloud-option-in-20-04-lts))
* Deja Dup + Google Drive. This is what I tried to set up once but failed to get it working. Maybe I should try again.

https://www.cloudwards.net/best-online-backup-for-linux/

Find more options: Google for [`ubuntu backup service`](https://www.google.com/search?channel=fs&client=ubuntu&q=ubuntu+backup+service).

## Ars Technica

Read [Ars Archivum: Top cloud backup services worth your money](https://arstechnica.com/information-technology/2023/02/ars-archivum-top-cloud-backup-services-worth-your-money/).

Jim Salter tried:

* IDrive (recommended). I had a terrible experience with [IDrive on Ubuntu](idrive.md) and gave up.
* BackBlaze
* Arq
* Carbonite
* Spideroak One

## Borg revisited

Users of borg use these backup services:

* rsync.net
* Backblaze

It seems Backblaze doesn't really support Borg. See question [Support for Borg / Borgmatic ?](https://www.reddit.com/r/backblaze/comments/pjbkf5/support_for_borg_borgmatic/) on Backblaze Reddit.

More tools to investigate:

* Borgmatic (looks like a declarative configuration layer for Borg)
* Restic (similar to Borg)

rsync.net offers a managed ZFS file system. That's great, but maybe too general for my needs.

BorgBase supports Borg and Restic backup tools. It shows a graphical user interface to make the backups easier to work with.

I will try BorgBase.

The makers of BorgBase are the makers of Borgmatic. This is a good sign.
