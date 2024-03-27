#!/bin/bash
secret_id="PrismaCloudCompute"
secret_region="us-east-1"
policy_name="PrismaCloudComputeAccessPolicy"
role_name="PrismaCloudComputeAccess"

# Variables
while getopts A:S:E:N:s:r:p:R flag
do
    case "${flag}" in
        A) access_key=${OPTARG};;
        S) secret_key=${OPTARG};;
        E) compute_api_endpoint=${OPTARG};;
        N) console_name=${OPTARG};;
        s) secret_id=${OPTARG};;
        r) secret_region=${OPTARG};;
        p) policy_name=${OPTARG};;
        R) role_name=${OPTARG};;
    esac
done

secret_arn=$(aws secretsmanager create-secret --name $secret_id --region $secret_region --secret-string '{
        "PrismaAccessKey":"'"$access_key"'",
        "PrismaSecretKey":"'"$secret_key"'",
        "PrismaConsoleAddress":"'"$compute_api_endpoint"'",
        "PrismaConsoleSAN":"'"$console_name"'"
    }' | grep -Po '"'"ARN"'"\s*:\s*"\K([^"]*)')

if [[ ! -z "$secret_arn" ]]
then
    policy_arn=$(aws iam create-policy --policy-name $policy_name --policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "GetPrismaCloudSecrets",
                "Effect": "Allow",
                "Action": "secretsmanager:GetSecretValue",
                "Resource": "'"$secret_arn"'"
            }
        ]
    }' | grep -Po '"'"Arn"'"\s*:\s*"\K([^"]*)')

    aws iam create-role --role-name $role_name --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }' > /dev/null
    sleep 10
    aws iam attach-role-policy --role-name $role_name --policy-arn $policy_arn > /dev/null
    aws iam create-instance-profile --instance-profile-name $role_name > /dev/null
    aws iam add-role-to-instance-profile --role-name $role_name --instance-profile-name $role_name > /dev/null
    
    if [ $? == 0 ]
    then
        echo "Process completed successfully!"
    else
        echo "Error while creating resources. Delete role $role_name or policy $policy_name if exists"
    fi

else
    aws secretsmanager update-secret --secret-id $secret_id --region $secret_region --secret-string '{
        "PrismaAccessKey":"'"$access_key"'",
        "PrismaSecretKey":"'"$secret_key"'",
        "PrismaConsoleAddress":"'"$compute_api_endpoint"'",
        "PrismaConsoleSAN":"'"$console_name"'"
    }' > /dev/null
fi