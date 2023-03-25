# Duplicati on S3

[Duplicati](https://github.com/duplicati/duplicati) is a free, open source, backup client that securely stores encrypted, incremental, compressed backups on cloud storage services and remote file servers. It works with more than a dozen storage providers including S3.

Jim Mendenhall [recommended it](Ubuntu_Backup_Services.md) as the open source alternative to his favorite, Crashplan.

Read [How the backup process works](https://duplicati.readthedocs.io/en/latest/appendix-a-how-the-backup-process-works/) and [How the restore process works](https://duplicati.readthedocs.io/en/latest/appendix-b-how-the-restore-process-works/). Lists, blocks, and hashes.

I like the idea of backing up to S3. Since I'm already using AWS, it allows me to keep everything under one bill. But it may be expensive. The S3 standard pricing is USD 0.023 per GB-month. That's more than twice as expensive than BorgBase, which charges USD 0.01 per GB-month.

And that's just for storage. After the free tier, data transfer out costs USD 0.09 per GB. That could make doing a full restore to my own computer not a bankrupter, but a noticable cost.

BorgBase charges only for storage, not for upload, download, or API calls.

I'll leave it for now and try BorgBase.
