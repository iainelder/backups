# IDrive

## 2023-02-08

### Create IDrive account

Sign up for an IDrive monthly plan.

Use a default encryption key.

When I click to download the client, it downloads a Windows executable.

A Linux or Ubuntu client is not clearly offered from the user interface.

See [Linux Backup via Scripts](https://www.idrive.com/linux-backup-scripts). This is mostly advertising for a Snowball-type physical data delivery.

See [Data Protection for your Linux machines using Scripts](https://www.idrive.com/readme), referred to as a Linux scripts README from the page above. This has all the technical documentation, but no download link.

Instead of a download link it says "Contact our support team for script package download link.".

### Request Download Link

Description:

```
Please share with me a download link for the Linux client/scripts.

On this page I see the technical documentation, but no download link.

https://www.idrive.com/readme

Instead it says "Contact our support team for script package download link."
```

I fill in all the same details in the contact form as those I just provided when creating my account.

I click "Report to Tech Support" and wait.

> We have received your query/feedback. Our support personnel will get back to you at the earliest via email. 

So far, I'm unimpressed.

An automatic email response:

> Your request for support has been received and assigned ticket #ID138535391. A representative will follow-up with you as soon as possible. 

## 2023-02-09

### Response from tech support

> We request you to refer to the below link to download and install the IDrive scripts for Linux operating system.

> https://www.idrive.com/online-backup-linux-download

This page seems to be hidden on the web site.

It does at least offer a script for download.

### Download IDrive script

First check the [release notes](https://www.idrive.com/release-info#linux).

The Linux scripts appear to be getting regular updates, once every couple of months or so.

Write an installation script. See [install_idrive.sh](install_idrive.sh).

There are various undocumented dependencies.

It appears that the scripts are intented to be installed in a user directory, not in a system directory. When I installed the scripts in `/opt/idrive`, I got errors like this during the setup.

```text
Failed to open file /opt/idrive//.serviceLocation. Reason: Permission denied
Failed to create service location file.
```

I gave up before I got it working. See below for my attempt.

### Follow the setup instructions

Read the [Linux FAQ](https://www.idrive.com/faq_linux).

Read the [Linux README](https://www.idrive.com/readme).

Create a "service path" for storing temporary data.

```bash
mkdir --parents "${HOME}/tmp/idrive"
```

Run the account setup script.

```bash
/opt/idrive/account_setting.pl
```

Accept the default service path.

Accept migration of scripts data to newer format.

Stop at error "Unable to download static Perl command line utility."

Complete transcript of installation attempt:

```text
==========================================================================================
Version: 2.36            Developed By: IDrive Inc.
-------------            -----------------------------------------------------------------
Status: --               IDrive Username: No logged in user
----------               -----------------------------------------------------------------
Storage Used: --         Linux Username: norm
==========================================================================================


Dear User, Please provide your details below.

Enter your service path [This location will be used to maintain the temporary data used by your scripts] [Optional]: 
Considering your default service directory...

Your scripts data is in older format and must be migrated to newer format to use the latest version of scripts. 
Do you wish to continue with the migration (y/n)? 
Enter your choice: y

Starting migration process.... 
Failed to open file /home/norm/.local/share/idrive//.serviceLocation. No such file or directory
Migration process completed. 

Starting IDrive Cron service...
IDrive Cron service started. 

Failed to open file /home/norm/.local/share/idrive/migrateSuccess. No such file or directory
Checking for compatible static Perl command line utility. It may take couple of minutes to complete, please wait... 
Cannot open directory '/'. Permission denied.
/downloads does not exists
==========================================================================================
Version: 2.36            Developed By: IDrive Inc.
-------------            -----------------------------------------------------------------
Status: --               IDrive Username: No logged in user
----------               -----------------------------------------------------------------
Storage Used: --         Linux Username: norm
==========================================================================================

Unable to download static Perl command line utility.
```

I give up with IDrive.

There must be a better Linux backup provider than this.
