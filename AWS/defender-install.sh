#!/bin/bash
sleep 30

# Update OS
sudo yum -y update
sudo yum -y upgrade

# Install docker
sudo yum install -y docker
sudo systemctl enable docker
sudo systemctl start docker

# Update hostname
[[ -z "${NEW_HOSTNAME}" ]] && NEW_HOSTNAME="${NEW_HOSTNAME}" 
sudo hostnamectl set-hostname ${NEW_HOSTNAME}

# Variables
ACCESS_KEY=$(aws secretsmanager get-secret-value --secret-id PrismaCloud-APP --query SecretString --output text --region us-east-2 | grep -Po '"'"PrismaAccessKey"'"\s*:\s*"\K([^"]*)')
SECRET_KEY=$(aws secretsmanager get-secret-value --secret-id PrismaCloud-APP --query SecretString --output text --region us-east-2 | grep -Po '"'"PrismaSecretKey"'"\s*:\s*"\K([^"]*)')
CONSOLE_ADDRESS=$(aws secretsmanager get-secret-value --secret-id PrismaCloud-APP --query SecretString --output text --region us-east-2 | grep -Po '"'"PrismaConsoleAddress"'"\s*:\s*"\K([^"]*)')
CONSOLE_SAN=$(aws secretsmanager get-secret-value --secret-id PrismaCloud-APP --query SecretString --output text --region us-east-2 | grep -Po '"'"PrismaConsoleSAN"'"\s*:\s*"\K([^"]*)')

# Get token
token=$(curl -s -k ${CONSOLE_ADDRESS}/api/v1/authenticate -X POST -H "Content-Type: application/json" -d '{
  "username":"'"$ACCESS_KEY"'",
  "password":"'"$SECRET_KEY"'"
  }'  | grep -Po '"'"token"'"\s*:\s*"\K([^"]*)')

# Download installation script
curl -sSL -O --header "authorization: Bearer $token" -X POST ${CONSOLE_ADDRESS}/api/v1/scripts/defender.sh

# Remove Memory limitation
sed -i '/${defender_envvars}/ased -i -e "s/-m 512m //g" twistlock.sh' defender.sh

# Install defender
cat defender.sh | sudo bash -s -- -c "$CONSOLE_CN" -v -m -u

# Clear data
rm defender.sh
history -c


