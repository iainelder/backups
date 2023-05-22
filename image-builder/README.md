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

2023-05-22: 

The stack creation completed it 1094 seconds, or 18 minutes. Check with this script.

```bash
aws cloudformation describe-stack-events \
--stack-name=ImageBuilder \
| jq '
  def timestamp:
    .Timestamp | sub("\\.[0-9]{6}\\+00:00$"; "Z") | fromdateiso8601
  ;

  (.StackEvents[0] | timestamp) - (.StackEvents[-1] | timestamp)
'
```

There is an image resource with an output AMI `ami-0d5876754b76567d6`.

```bash
aws imagebuilder get-image \
--image-build-version-arn=arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/1
```

```json
{
    "requestId": "cf1dbfb7-2646-4482-96b6-dfd7bd4a1336",
    "image": {
        "arn": "arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/1",
        "type": "AMI",
        "name": "Ubuntu-2004-with-latest-SSM-Agent",
        "version": "0.0.1/1",
        "platform": "Linux",
        "enhancedImageMetadataEnabled": true,
        "osVersion": "Ubuntu 20",
        "state": {
            "status": "AVAILABLE"
        },
        "imageRecipe": {
            "arn": "arn:aws:imagebuilder:eu-west-1:726356392388:image-recipe/ubuntu-2004-with-latest-ssm-agent/0.0.1",
            "name": "Ubuntu-2004-with-latest-SSM-Agent",
            "platform": "Linux",
            "version": "0.0.1",
            "components": [
                {
                    "componentArn": "arn:aws:imagebuilder:eu-west-1:aws:component/update-linux/1.0.2/1"
                }
            ],
            "parentImage": "arn:aws:imagebuilder:eu-west-1:aws:image/ubuntu-server-20-lts-x86/2023.5.2/1",
            "blockDeviceMappings": [],
            "dateCreated": "2023-05-17T21:14:46.385Z",
            "tags": {},
            "additionalInstanceConfiguration": {}
        },
        "infrastructureConfiguration": {
            "arn": "arn:aws:imagebuilder:eu-west-1:726356392388:infrastructure-configuration/ubuntu-2004-with-latest-ssm-agent-infrastructure-configuration",
            "name": "Ubuntu-2004-with-latest-SSM-Agent-Infrastructure-Configuration",
            "instanceProfileName": "ImageBuilder-InstanceProfile-Lz69uJLtnkj6",
            "logging": {
                "s3Logs": {
                    "s3BucketName": "imagebuilder-imagebuilderlogbucket-1tf2y054qgkjx"
                }
            },
            "terminateInstanceOnFailure": true,
            "dateCreated": "2023-05-17T21:17:17.722Z",
            "tags": {}
        },
        "imageTestsConfiguration": {
            "imageTestsEnabled": true,
            "timeoutMinutes": 720
        },
        "dateCreated": "2023-05-17T21:17:21.283Z",
        "outputResources": {
            "amis": [
                {
                    "region": "eu-west-1",
                    "image": "ami-0d5876754b76567d6",
                    "name": "Ubuntu-2004-with-latest-SSM-Agent 2023-05-17T21-17-23.099935Z",
                    "accountId": "726356392388"
                }
            ]
        },
        "tags": {},
        "buildType": "USER_INITIATED"
    }
}
```

```bash
aws imagebuilder list-workflow-executions \
--image-build-version-arn=arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/1
```

The build and test workflows completed in 905 seconds, or 15 minutes.

```json
{
    "requestId": "2d1613a3-929a-45bc-87b3-78211e3ace64",
    "workflowExecutions": [
        {
            "workflowBuildVersionArn": "arn:aws:imagebuilder:eu-west-1:aws:workflow/build/build-image/1.0.0/1",
            "workflowExecutionId": "wf-1e54ae78-b191-46ea-9b3c-5bcc99707989",
            "status": "COMPLETED",
            "totalStepCount": 7,
            "totalStepsSucceeded": 6,
            "totalStepsFailed": 0,
            "totalStepsSkipped": 1,
            "startTime": "2023-05-17T21:17:32.156Z",
            "endTime": "2023-05-17T21:27:47.266Z"
        },
        {
            "workflowBuildVersionArn": "arn:aws:imagebuilder:eu-west-1:aws:workflow/test/test-image/1.0.0/1",
            "workflowExecutionId": "wf-5d349388-5c5a-4175-9831-7796eb78ab96",
            "status": "COMPLETED",
            "totalStepCount": 4,
            "totalStepsSucceeded": 3,
            "totalStepsFailed": 0,
            "totalStepsSkipped": 1,
            "startTime": "2023-05-17T21:27:52.717Z",
            "endTime": "2023-05-17T21:32:37.873Z"
        }
    ],
    "imageBuildVersionArn": "arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/1"
}
```

To compute workflow duration:

```bash
aws imagebuilder list-workflow-executions \
--image-build-version-arn=arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/1 \
| jq '
  def timestamp:
    sub("\\.[0-9]{3}Z$"; "Z") | fromdateiso8601
  ;

  .workflowExecutions | (.[-1].endTime | timestamp) - (.[0].startTime | timestamp)
'
```

How do I create a new image using the same configuration?

There is no pipeline in the stack.

The stack creates the following Image Builder resources:

* Image
* ImageRecipe
* InfrastructureConfiguration

What it lacks is an ImagePipeline, which would allow repeated builds.

2023-05-22: Copy the original template and adapt it for my needs.

```bash
wget "https://raw.githubusercontent.com/aws-samples/amazon-ec2-image-builder-samples/master/CloudFormation/Linux/ubuntu-2004-with-latest-ssm-agent/ubuntu-2004-with-latest-ssm-agent.yml"
```

Add an ImagePipeline resource to the template.

Deploy the change to the stack.

```bash
aws cloudformation update-stack \
--stack-name=ImageBuilder \
--template-body="file://ubuntu-2004-with-latest-ssm-agent.yml" \
--capabilities=CAPABILITY_IAM
```

Now I have an image pipeline.

```console
$ aws imagebuilder list-image-pipelines
{
    "requestId": "e430321e-a2dc-4e99-a519-a908d317603f",
    "imagePipelineList": [
        {
            "arn": "arn:aws:imagebuilder:eu-west-1:726356392388:image-pipeline/ubuntu-2004-with-latest-ssm-agent-pipeline",
            "name": "Ubuntu-2004-with-latest-SSM-Agent-Pipeline",
            "platform": "Linux",
            "enhancedImageMetadataEnabled": true,
            "imageRecipeArn": "arn:aws:imagebuilder:eu-west-1:726356392388:image-recipe/ubuntu-2004-with-latest-ssm-agent/0.0.1",
            "infrastructureConfigurationArn": "arn:aws:imagebuilder:eu-west-1:726356392388:infrastructure-configuration/ubuntu-2004-with-latest-ssm-agent-infrastructure-configuration",
            "imageTestsConfiguration": {
                "imageTestsEnabled": true,
                "timeoutMinutes": 720
            },
            "status": "ENABLED",
            "dateCreated": "2023-05-22T21:28:26.886Z",
            "dateUpdated": "2023-05-22T21:28:26.886Z",
            "tags": {}
        }
    ]
}
```

And now I can start a new execution of the pipeline like this.

```console
$ aws imagebuilder start-image-pipeline-execution --image-pipeline-arn "arn:aws:imagebuilder:eu-west-1:726356392388:image-pipeline/ubuntu-2004-with-latest-ssm-agent-pipeline"
{
    "requestId": "12022975-344e-44ea-acf9-251243214a7e",
    "clientToken": "e396a497-9275-4edb-a61e-2c82194af853",
    "imageBuildVersionArn": "arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/2"
}
```

List the workflow executions of the second build of the image.

```console
$ aws imagebuilder list-workflow-executions \
  --image-build-version-arn=arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/2
{
    "requestId": "3a02db01-b5c3-44c1-9b95-45d425c0cea6",
    "workflowExecutions": [
        {
            "workflowBuildVersionArn": "arn:aws:imagebuilder:eu-west-1:aws:workflow/build/build-image/1.0.0/1",
            "workflowExecutionId": "wf-99b94dde-9a96-43d3-a84c-178eaa804f2f",
            "status": "COMPLETED",
            "totalStepCount": 7,
            "totalStepsSucceeded": 6,
            "totalStepsFailed": 0,
            "totalStepsSkipped": 1,
            "startTime": "2023-05-22T21:33:03.240Z",
            "endTime": "2023-05-22T21:42:31.545Z"
        },
        {
            "workflowBuildVersionArn": "arn:aws:imagebuilder:eu-west-1:aws:workflow/test/test-image/1.0.0/1",
            "workflowExecutionId": "wf-9b914ab8-b527-481f-b321-cc29eac6d18e",
            "status": "COMPLETED",
            "totalStepCount": 4,
            "totalStepsSucceeded": 3,
            "totalStepsFailed": 0,
            "totalStepsSkipped": 1,
            "startTime": "2023-05-22T21:42:37.429Z",
            "endTime": "2023-05-22T21:47:22.596Z"
        }
    ],
    "imageBuildVersionArn": "arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/2"
}
```

List the image build versions for the for image version.

```console
$ aws imagebuilder list-image-build-versions --image-version-arn arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1
{
    "requestId": "8eb7dd6a-60ae-4ba0-98bd-2cdb652b3bbb",
    "imageSummaryList": [
        {
            "arn": "arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/2",
            "name": "Ubuntu-2004-with-latest-SSM-Agent",
            "type": "AMI",
            "version": "0.0.1/2",
            "platform": "Linux",
            "osVersion": "Ubuntu 20",
            "state": {
                "status": "AVAILABLE"
            },
            "owner": "726356392388",
            "dateCreated": "2023-05-22T21:32:58.114Z",
            "outputResources": {
                "amis": [
                    {
                        "region": "eu-west-1",
                        "image": "ami-067552386ac06dc8d",
                        "name": "Ubuntu-2004-with-latest-SSM-Agent 2023-05-22T21-32-59.911021Z",
                        "accountId": "726356392388"
                    }
                ]
            },
            "tags": {},
            "buildType": "USER_INITIATED"
        },
        {
            "arn": "arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/1",
            "name": "Ubuntu-2004-with-latest-SSM-Agent",
            "type": "AMI",
            "version": "0.0.1/1",
            "platform": "Linux",
            "osVersion": "Ubuntu 20",
            "state": {
                "status": "AVAILABLE"
            },
            "owner": "726356392388",
            "dateCreated": "2023-05-17T21:17:21.283Z",
            "outputResources": {
                "amis": [
                    {
                        "region": "eu-west-1",
                        "image": "ami-0d5876754b76567d6",
                        "name": "Ubuntu-2004-with-latest-SSM-Agent 2023-05-17T21-17-23.099935Z",
                        "accountId": "726356392388"
                    }
                ]
            },
            "tags": {},
            "buildType": "USER_INITIATED"
        }
    ]
}
```

How do I delete old images?

The [DeleteImage](https://docs.aws.amazon.com/imagebuilder/latest/APIReference/API_DeleteImage.html) documentation says that it does not delete any AMIs.

What if I delete the AMI and not the image in Image Builder?

```console
$ aws ec2 describe-images --image-id ami-0d5876754b76567d6
{
    "Images": [
        {
            "Architecture": "x86_64",
            "CreationDate": "2023-05-17T21:25:26.000Z",
            "ImageId": "ami-0d5876754b76567d6",
            "ImageLocation": "726356392388/Ubuntu-2004-with-latest-SSM-Agent 2023-05-17T21-17-23.099935Z",
            "ImageType": "machine",
            "Public": false,
            "OwnerId": "726356392388",
            "PlatformDetails": "Linux/UNIX",
            "UsageOperation": "RunInstances",
            "State": "available",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/sda1",
                    "Ebs": {
                        "DeleteOnTermination": true,
                        "SnapshotId": "snap-0106b86c0450fed6f",
                        "VolumeSize": 8,
                        "VolumeType": "gp2",
                        "Encrypted": false
                    }
                },
                {
                    "DeviceName": "/dev/sdb",
                    "VirtualName": "ephemeral0"
                },
                {
                    "DeviceName": "/dev/sdc",
                    "VirtualName": "ephemeral1"
                }
            ],
            "EnaSupport": true,
            "Hypervisor": "xen",
            "Name": "Ubuntu-2004-with-latest-SSM-Agent 2023-05-17T21-17-23.099935Z",
            "RootDeviceName": "/dev/sda1",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "Tags": [
                {
                    "Key": "CreatedBy",
                    "Value": "EC2 Image Builder"
                },
                {
                    "Key": "Ec2ImageBuilderArn",
                    "Value": "arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/1"
                }
            ],
            "VirtualizationType": "hvm"
        }
    ]
}
```

Delete the image and its snapshot.

```bash
aws ec2 deregister-image --image-id ami-0d5876754b76567d6
aws ec2 delete-snapshot --snapshot-id snap-0106b86c0450fed6f
```

The image builder API doesn't show any change. It still says "AVAILABLE".

```console
$ aws imagebuilder list-image-build-versions --image-version-arn arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1
{
    "requestId": "ee230f37-38d9-4f2f-8fdb-52afedb96546",
    "imageSummaryList": [
        {
            "arn": "arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/2",
            "name": "Ubuntu-2004-with-latest-SSM-Agent",
            "type": "AMI",
            "version": "0.0.1/2",
            "platform": "Linux",
            "osVersion": "Ubuntu 20",
            "state": {
                "status": "AVAILABLE"
            },
            "owner": "726356392388",
            "dateCreated": "2023-05-22T21:32:58.114Z",
            "outputResources": {
                "amis": [
                    {
                        "region": "eu-west-1",
                        "image": "ami-067552386ac06dc8d",
                        "name": "Ubuntu-2004-with-latest-SSM-Agent 2023-05-22T21-32-59.911021Z",
                        "accountId": "726356392388"
                    }
                ]
            },
            "tags": {},
            "buildType": "USER_INITIATED"
        },
        {
            "arn": "arn:aws:imagebuilder:eu-west-1:726356392388:image/ubuntu-2004-with-latest-ssm-agent/0.0.1/1",
            "name": "Ubuntu-2004-with-latest-SSM-Agent",
            "type": "AMI",
            "version": "0.0.1/1",
            "platform": "Linux",
            "osVersion": "Ubuntu 20",
            "state": {
                "status": "AVAILABLE"
            },
            "owner": "726356392388",
            "dateCreated": "2023-05-17T21:17:21.283Z",
            "outputResources": {
                "amis": [
                    {
                        "region": "eu-west-1",
                        "image": "ami-0d5876754b76567d6",
                        "name": "Ubuntu-2004-with-latest-SSM-Agent 2023-05-17T21-17-23.099935Z",
                        "accountId": "726356392388"
                    }
                ]
            },
            "tags": {},
            "buildType": "USER_INITIATED"
        }
    ]
}
```