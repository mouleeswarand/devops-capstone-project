#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/jenkins-bootstrap.log) 2>&1

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg fontconfig openjdk-21-jre ansible-core git unzip

# Install Jenkins from its official Debian package repository.
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  -o /etc/apt/keyrings/jenkins-keyring.asc
chmod 0644 /etc/apt/keyrings/jenkins-keyring.asc

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# Install AWS CLI v2.
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# Install kubectl for EKS management.
curl -fsSLo /usr/local/bin/kubectl \
  https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod 0755 /usr/local/bin/kubectl

# Add the Ubuntu administrator to the Jenkins group only if needed.
usermod -aG jenkins ubuntu || true

echo "Jenkins bootstrap finished."
