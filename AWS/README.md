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

#### Step 2: Create Prisma Cloud Service Account
On Prisma Cloud create the following resources:
1. **Permissions Group**: this group must be granted with View and Update Defender Management permissions.
2. **Role**: Attach the newly created Permissions Group to a new role.
3. **Service Account**: Create a new service account with the newly created role. This should also create an access key and secret key to authenticate with Prisma Cloud.

#### Step 3: Create Secret
On AWS Secrets Manager, create a secret with the name of **PrismaCloudCompute** on **us-east-1** by preference. This secret should contain the following keys:

- **PCC_URL**: Path to the Compute Console. This should be obtained in Prisma Cloud > Runtime Security > Manage > System > Utilities > Path to the Console.
- **PCC_USER**: Access Key of the Service Account created on Step 2.
- **PCC_PASS**: Secret Key of the Service Account created on Step 2.
- **PCC_SAN**: Console FQDN. Can be obtained from the PCC_URL variable.

#### Step 4: Setup AWS Authentication (optional)
If you are not running the terraform from AWS Cloud Shell, then run the following commands:
```bash
export AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="AWS_SECRET_KEY"
export AWS_REGION="AWS_REGION"
```

Replace the values of AWS_ACCESS_KEY and AWS_SECRET_KEY with the ones that belong to the user to be used to deploy the infrastructure and the AWS_REGION is where the AS Group will be located. This user must have access to retrieve the secret created in step 3 and deploy all the required infrastructure.

#### Step 5: Setup Terraform Variables
In Terraform you can use Terraform Cloud to store the variables or use a .tfvars file. The variables are located under the file *AWS/variables.tf*. These variables are:
 
* **secret_id**: name or ARN of the Secret to be used. Must match the value of Step 3.
* **secret_region**: region where the secret is located. Must match the value of Step 3.
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

#### Step 6: Deploy Infrastructure
Run the following commands:
```bash
terraform init
terraform apply --auto-approve
```

