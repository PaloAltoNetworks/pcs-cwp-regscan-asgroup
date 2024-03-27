#!/bin/bash
# Get current Prisma Cloud Compute Console version

# Secret Variables
while getopts s:r:a:h:R: flag
do
    case "${flag}" in
        s) secret_id=${OPTARG};;
        r) secret_region=${OPTARG};;
        a) ami_name=${OPTARG};;
        h) new_hostname=${OPTARG};;
        R) ec2_role=${OPTARG};;
    esac
done

ACCESS_KEY=$(aws secretsmanager get-secret-value --secret-id ${secret_id} --query SecretString --output text --region ${secret_region} | grep -Po '"'"PrismaAccessKey"'"\s*:\s*"\K([^"]*)')
SECRET_KEY=$(aws secretsmanager get-secret-value --secret-id ${secret_id} --query SecretString --output text --region ${secret_region} | grep -Po '"'"PrismaSecretKey"'"\s*:\s*"\K([^"]*)')
CONSOLE_ADDRESS=$(aws secretsmanager get-secret-value --secret-id ${secret_id} --query SecretString --output text --region ${secret_region} | grep -Po '"'"PrismaConsoleAddress"'"\s*:\s*"\K([^"]*)')

token=$(curl -s -k ${CONSOLE_ADDRESS}/api/v1/authenticate -X POST -H "Content-Type: application/json" -d '{
  "username":"'"$ACCESS_KEY"'",
  "password":"'"$SECRET_KEY"'"
  }'  | grep -Po '"'"token"'"\s*:\s*"\K([^"]*)')

version=$(curl -s -k ${CONSOLE_ADDRESS}/api/v1/version -H "Authorization: Bearer $token" | tr -d '"' | sed "s/\./_/g")

packer init registry-scanner.pkr.hcl
packer validate -var "ami_name=${ami_name}" -var "secret_id=${secret_id}" -var "secret_region=${secret_region}" -var "console_version=${version}" -var "hostname=${new_hostname}" -var "ec2_role=${ec2_role}" registry-scanner.pkr.hcl
packer build -var "ami_name=${ami_name}" -var "secret_id=${secret_id}" -var "secret_region=${secret_region}" -var "console_version=${version}" -var "hostname=${new_hostname}" -var "ec2_role=${ec2_role}" registry-scanner.pkr.hcl