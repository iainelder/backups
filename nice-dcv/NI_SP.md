# NI SP

I subscribe to the Ubuntu 20 Desktop - NICE DCV High-End Remote Desktop (no GPU) from NI SP.

* Product ID in eu-west-1: 3f7ae378-e34a-401d-95b0-3f98e55fe145
* AMI ID: ami-0237e1ecd42b980a1

## First run

I start a t3.medium instance.

I don't manage to log into the instance on the first run.

The instance creation process in the Marketplace console forces you to assign a key pair.

The only key pair I have in the account region is one that I no longer have the private part of.

That wouldn't matter except that the usage instructions show that you need to use SSH to set a password for the ubuntu user before you can log in using the NICE DCV client.

I tried logging in using Session Manager, but the instance was not reachable.

I don't know whether the Session Manager agent is installed on the instance.

The Aranda solution is simpler to use, so I will use that one instead.
