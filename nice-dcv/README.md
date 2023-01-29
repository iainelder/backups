# Ubuntu 20.04 over NICE DCV

A CloudFormation template to run Ubuntu 20.04 over NICE DCV.

Tested only in default VPC for now.

TODO: Replace my own janky attempt to configure NICE DCV with the Arana AMI.

TODO: Try the NI SP AMI.

## Connect via Session Manager

```bash
aws-gate session Ubuntu
```

## Deploy

```bash
aws ec2 describe-subnets \
--filters "Name=availability-zone,Values=eu-west-1a" \
| jq -j '.Subnets[0].SubnetId' \
> /tmp/subnet_id

aws ec2 describe-security-groups \
--filters "Name=group-name,Values=default" \
| jq -j '.SecurityGroups[0].GroupId' \
> /tmp/security_group_id

sam deploy \
--stack-name ubuntu1 \
--template-file template.yml \
--parameter-overrides \
  SecurityGroup="$(cat /tmp/security_group_id)" \
  Subnet="$(cat /tmp/subnet_id)" \
--capabilities CAPABILITY_IAM
```

## Test with Taskcat

Taskcat creates and deletes the stack. Later I'll run this in CI.

```bash
aws ec2 describe-subnets \
--filters "Name=availability-zone,Values=eu-west-1a" \
| jq -j '.Subnets[0].SubnetId' \
> /tmp/subnet_id

aws ec2 describe-security-groups \
--filters "Name=group-name,Values=default" \
| jq -j '.SecurityGroups[0].GroupId' \
> /tmp/security_group_id

cat > ~/.taskcat.yml <<EOF
general:
  parameters:
    SecurityGroup: $(cat /tmp/security_group_id)
    Subnet: $(cat /tmp/subnet_id)
EOF

taskcat test run
```

## Marketplace Solutions

Building a NICE DCV remote desktop is hard.

I found these marketplace solutions for it.

From [NI SP](https://www.ni-sp.com/):

* [Ubuntu 20 Desktop - NICE DCV High-End Remote Desktop (no GPU)](https://aws.amazon.com/marketplace/pp/prodview-nx7ccy5g7e5k2?sr=0-16&ref_=beagle&applicationId=AWSMPContessa)
* [Ubuntu 22 Desktop - NICE DCV High-End Remote Desktop (no GPU)](https://aws.amazon.com/marketplace/pp/prodview-iccvz46zbfyb4?sr=0-7&ref_=beagle&applicationId=AWSMPContessa)

From [Arara Solutions](http://arara.solutions/):

* [Ubuntu Desktop 22.04 LTS - GUI Gnome with NICE DCV](https://aws.amazon.com/marketplace/pp/prodview-qqosm3zfgej3g?sr=0-3&ref_=beagle&applicationId=AWSMPContessa)
* [Ubuntu Desktop 20.04 LTS - GUI Gnome with NICE DCV](https://aws.amazon.com/marketplace/pp/prodview-pg3jtbysn3442?sr=0-5&ref_=beagle&applicationId=AWSMPContessa)
