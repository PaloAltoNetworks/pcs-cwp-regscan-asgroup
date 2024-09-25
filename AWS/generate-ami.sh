#!/bin/bash

# Secret Variables
while getopts s:r:a:h:R:S: flag
do
    case "${flag}" in
        s) secret_id=${OPTARG};;
        R) secret_region=${OPTARG};;
        r) region=${OPTARG};;
        a) ami_name=${OPTARG};;
        h) new_hostname=${OPTARG};;
        S) subnet_id=${OPTARG};;
    esac
done

[[ -z $region ]] && region=$AWS_REGION
[[ -z $secret_region ]] && secret_region=$region


# Get current Prisma Cloud Compute Console version
PCC_USER=$(aws secretsmanager get-secret-value --secret-id ${secret_id} --query SecretString --output text --region ${secret_region} | grep -Po '"'"PCC_USER"'"\s*:\s*"\K([^"]*)')
PCC_PASS=$(aws secretsmanager get-secret-value --secret-id ${secret_id} --query SecretString --output text --region ${secret_region} | grep -Po '"'"PCC_PASS"'"\s*:\s*"\K([^"]*)')
PCC_URL=$(aws secretsmanager get-secret-value --secret-id ${secret_id} --query SecretString --output text --region ${secret_region} | grep -Po '"'"PCC_URL"'"\s*:\s*"\K([^"]*)')
PCC_SAN=$(aws secretsmanager get-secret-value --secret-id ${secret_id} --query SecretString --output text --region ${secret_region} | grep -Po '"'"PCC_SAN"'"\s*:\s*"\K([^"]*)')

token=$(curl -s -k ${PCC_URL}/api/v1/authenticate -X POST -H "Content-Type: application/json" -d '{
  "username":"'"$PCC_USER"'",
  "password":"'"$PCC_PASS"'"
  }' | grep -Po '"'"token"'"\s*:\s*"\K([^"]*)')

version=$(curl -s -k ${PCC_URL}/api/v1/version -H "Authorization: Bearer $token" | tr -d '"' | sed "s/\./_/g")

# Build the AMI
packer init registry-scanner.pkr.hcl
packer validate \
  -var "ami_name=${ami_name}" \
  -var "region=${region}" \
  -var "console_version=${version}" \
  -var "hostname=${new_hostname}" \
  -var "token=${token}" \
  -var "pcc_url=${PCC_URL}" \
  -var "pcc_san=${PCC_SAN}" \
  -var "subnet_id=${subnet_id}" \
  registry-scanner.pkr.hcl

packer build \
  -var "ami_name=${ami_name}" \
  -var "region=${region}" \
  -var "console_version=${version}" \
  -var "hostname=${new_hostname}" \
  -var "token=${token}" \
  -var "pcc_url=${PCC_URL}" \
  -var "pcc_san=${PCC_SAN}" \
  -var "subnet_id=${subnet_id}" \
  registry-scanner.pkr.hcl
