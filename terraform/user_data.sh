#!/usr/bin/env bash
# ==============================================================================
# Docker Learning Lab - EC2 Bootstrap User Data Script
# Runs once on first instance launch as root
# ==============================================================================

set -euo pipefail
exec > >(tee -a /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting Docker Learning Lab Provisioning"
echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "=========================================="

export DEBIAN_FRONTEND=noninteractive

# Update apt repositories and upgrade installed packages
echo "[1/6] Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install required core utilities and tools
echo "[2/6] Installing core utilities (git, curl, wget, vim, nano, htop, tree, unzip)..."
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  wget \
  git \
  vim \
  nano \
  htop \
  tree \
  unzip \
  software-properties-common

# Install official AWS CLI v2
echo "[3/6] Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
  rm -rf /tmp/aws /tmp/awscliv2.zip
  echo "AWS CLI installed successfully: $(aws --version)"
else
  echo "AWS CLI is already installed: $(aws --version)"
fi

# Configure official Docker repository and install Docker Engine + Compose plugin
echo "[4/6] Setting up Docker official repository..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

echo "[5/6] Installing Docker Engine, CLI, containerd, and Docker Compose plugin..."
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Enable and start Docker daemon
systemctl enable docker
systemctl start docker

# Add ubuntu user to docker group to run docker commands without sudo
usermod -aG docker ubuntu

# Configure custom welcome banner (MOTD) for Docker learning lab
echo "[6/6] Configuring lab workspace and environment..."
cat << 'EOF' > /etc/update-motd.d/99-docker-lab
#!/bin/sh
cat << "BANNER"
========================================================================
       __             __               __                              
  ____/ /____  _____/ /_____  _____   / /___ _____ _   ____ ___  ____ _
 / __  / __ \/ ___/ //_/ _ \/ ___/  / / __ `/ __ `/  / __ `__ \/ __ `/
/ /_/ / /_/ / /__/ ,< /  __/ /     / / /_/ / /_/ /  / / / / / / /_/ / 
\__,_/\____/\___/_/|_|\___/_/     /_/\__,_/\__, (_) \_/ /_/ /_/\__,_/  
                                          /____/                       
========================================================================
Welcome to your Docker Learning Lab on AWS!

• Docker Status:  $(systemctl is-active docker)
• Docker Version: $(docker --version 2>/dev/null || echo "initializing...")
• Compose Plugin: $(docker compose version 2>/dev/null || echo "initializing...")
• Lab Directory:  ~/workspace

Happy Containerizing!
========================================================================
BANNER
EOF
chmod +x /etc/update-motd.d/99-docker-lab

# Create workspace directory for user ubuntu
mkdir -p /home/ubuntu/workspace
chown -R ubuntu:ubuntu /home/ubuntu/workspace

# Mark completion
touch /var/log/user-data-completed
echo "=========================================="
echo "Docker Learning Lab Provisioning COMPLETED"
echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "=========================================="
