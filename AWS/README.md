# EC2 Auto Scaling Group deployment
​​This repo showcases the process of how to scan a container image registry using a AWS EC2 autoscaling group.

## Introduction
**Objective**
<br>
Discover how to prepare the AMI, create the Launch Template and create the auto scaling group for registry scanning. 

**Environment**
* AWS Account
* Prisma Cloud SaaS or self-hosted tenant

**Requirements**
* Have installed in the workstation the following:
    * [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
    * [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
    * [Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli)
    * [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

## Process
This process uses the following:
* **AWS Secrets Manager**: Vault to store secrets of Prisma Cloud.
* **Packer**: A tool that is being used to automate the process of AMI creation.
* **Terraform**: tool used to automate the deployment of infrastructure in AWS.

### Part 1: Setup the Infrastructure

#### Step 1: Download Github Repository
Run the following command:
```bash
git clone https://github.com/PaloAltoNetworks/pcs-cwp-regscan-asgroup.git
```

This shall download all the files required for setting up the infrastructure.

#### Step 2: Create AWS User for Automation
1. Update the file *AutomationRegScanPolicy.json*, which is located in this folder of the repository, by substitute the following values:
    * **ACCOUNT_ID**: which this is the ID of the AWS Account
    * **EC2_ROLE**: The automation process will create a role to be attached to an EC2 instance. This shall be the name of the role that will be created. By default it is PrismaCloudComputeAccess.

2. On AWS Console, create the policy AutomationRegScanPolicy with the updated document.

3. Once the policy is being created, create the user automation-regscan and attach the AutomationRegScanPolicy.

4. Create an Access Key for this user.

#### Step 3: Create Prisma Cloud Service Account
On Prisma Cloud create the following resources:
1. **Permissions Group**: this group must be granted with View and Update Defender Management permissions.
2. **Role**: Attach the newly created Permissions Group to a new role.
3. **Service Account**: Create a new service account with the newly created role. This should also create an access key and secret key to authenticate with Prisma Cloud.

#### Step 4: Setup AWS Authentication
Run the following commands:
```bash
export AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="AWS_SECRET_KEY"
```

Replace the values of AWS_ACCESS_KEY and AWS_SECRET_KEY with the ones that belong to the user created in AWS.

#### Step 5: Create IAM Role and Secrets
On this folder of the repository there's a file called build-role-and-secrets.sh. This file what it does is the following:
1. Generates a Secret in AWS Secrets Manager. This secret contains the Access Key and Secret Key of the created Service Account, and also the endpoint of the Prisma Cloud Compute console and the console name.
2. Creates a Policy that only allows access to the Secret generated.
3. Creates an IAM Role to be used for the instance to retrieve the secrets from AWS Secrets Manager.
4. Creates an IAM Instance Profile to attach the newly created role to an EC2 instance.

Run the script as the following command:
```bash
bash build-role-and-secrets.sh -A PRISMA_ACCESS_KEY -S PRISMA_SECRET_KEY -a CONSOLE_ADDRESS -N CONSOLE_NAME -s SECRET_NAME -r SECRET_REGION -p POLICY_NAME -R ROLE_NAME
```
The parameters are the following:
* **PRISMA_ACCESS_KEY** (required): Access Key of the Prisma Cloud Service Account created on Step 3.
* **PRISMA_SECRET_KEY** (required): Secret Key of the Prisma Cloud Service Account created on Step 3.
* **CONSOLE_ADDRESS** (required): Url of the compute console. This should be obtained in Prisma Cloud > Runtime Security > Manage > System > Utilities at the bottom of the page.
* **CONSOLE_NAME** (required): the FQDN of the console. Can be obtained from CONSOLE_ADDRESS.
* **SECRET_NAME** (optional): Name of the secret to be created. By default it is PrismaCloudCompute.
* **SECRET_REGION** (optional): Region where the secret will be created. By default it is us-east-1.
* **POLICY_NAME** (optional): Name of the policy to be created. By default it is PrismaCloudComputeAccessPolicy.
* **ROLE_NAME** (optional): Name of the role to be created. By default it is PrismaCloudComputeAccess 

#### Step 6: Setup Terraform Variables
In Terraform you can use Terraform Cloud to store the variables or use a .tfvars file. The variables are located under the file *AWS/variables.tf*. These variables are:
 
* **secret_id**: name or ARN of the Secret to be used. Must match the value of Step 5.
* **secret_region**: region where the secret is located. Must match the value of Step 5.
* **ec2_role**: name of the role to be used. Must match the value of Step 5.
* **ami_name**: name prefix of the AMI to be created. The final name of the AMI will be the combination of this value, plus the Defender version which will be installed and the current timestamp. 
* **hostname**: name to be used by the registry scanning instances. It is recommended to use the following format:

    registry-scanner-ACCOUNT_ID.REGION.ENTREPRISE_DOMAIN 

	Where:
    * **ACCOUNT_ID**: is the ID of the AWS account.
    * **REGION**: is the AWS region.
    * **ENTERPRISE_DOMAIN**: is the domain name of the enterprise

* **launch_template_name**: name of the launch template.
* **asgroup_name**: name of the EC2 Auto Scaling group.
* **asgroup_max_instances**: Maximum number of instances to be used for the AS Group.
* **asgroup_instance_type**: the type of EC2 instances to be used in the AS Group.
* **vpc_name**: The name of the VPC to be created.
* **vpc_cidr**: the CIDR Block of the VPC.
* **public_subnets**: List of subnets CIDR Blocks to be used. Must be contained on the VPC CIDR.
* **security_group_name**: Name of the Security Group to be used for the EC2 instances in the AS Group.
* **egress_cidr**: CIDR Block to allow Outbound access on port 443. It is recommended to use the Compute Console Egress IP for the tenant in which your Prisma Cloud tenant is located.   

#### Step 7: Deploy Infrastructure
Run the following commands:
```bash
terraform init
terraform apply --auto-approve
```