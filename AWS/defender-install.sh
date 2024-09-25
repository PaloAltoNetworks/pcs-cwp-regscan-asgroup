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
sudo hostnamectl set-hostname ${NEW_HOSTNAME}

# Download installation script
curl -sSL -O --header "authorization: Bearer $TOKEN" -X POST ${PCC_URL}/api/v1/scripts/defender.sh

# Remove Memory limitation
sed -i '/${defender_envvars}/ased -i -e "s/-m 512m //g" twistlock.sh' defender.sh

# Install defender
cat defender.sh | sudo bash -s -- -c "$PCC_SAN" -v -m -u

# Clear data
rm defender.sh
history -c