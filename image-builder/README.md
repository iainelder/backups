# Image Builder

2023-05-17: Use the [Ubuntu 20.04 sample template](https://github.com/aws-samples/amazon-ec2-image-builder-samples/tree/master/CloudFormation/Linux/ubuntu-2004-with-latest-ssm-agent) as a base.

```bash
tmp="$(mktemp)"

curl \
--silent \
--show-error \
--url="https://raw.githubusercontent.com/aws-samples/amazon-ec2-image-builder-samples/master/CloudFormation/Linux/ubuntu-2004-with-latest-ssm-agent/ubuntu-2004-with-latest-ssm-agent.yml" \
--output="$tmp"

aws cloudformation create-stack \
--stack-name=ImageBuilder \
--template-body="file://$tmp" \
--capabilities=CAPABILITY_IAM
```

The documentation says that the stack will complete when the first image is created.

I'll check it again later.
