#!/bin/bash
set -e

exec > /var/log/user-data.log 2>&1

apt update -y
apt upgrade -y

hostnamectl set-hostname x2go-desktop-lab

# GUI ve X2Go
apt install -y xfce4 xfce4-goodies
apt install -y x2goserver x2goserver-xsession
apt install -y curl wget unzip docker.io docker-compose

# Docker
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Swap
fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Kullanıcılar
id -u user1 >/dev/null 2>&1 || useradd -m -s /bin/bash user1
echo "user1:TempPass123!" | chpasswd

id -u user2 >/dev/null 2>&1 || useradd -m -s /bin/bash user2
echo "user2:TempPass123!" | chpasswd
usermod -aG sudo user1
usermod -aG sudo user2
echo "user1 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "user2 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

echo "startxfce4" > /home/user1/.xsession
echo "startxfce4" > /home/user2/.xsession
chown user1:user1 /home/user1/.xsession
chown user2:user2 /home/user2/.xsession

# SSH password login - güçlü ve kalıcı ayar
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak || true

sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?KbdInteractiveAuthentication .*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?UsePAM .*/UsePAM yes/' /etc/ssh/sshd_config

grep -q '^PasswordAuthentication yes' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
grep -q '^KbdInteractiveAuthentication yes' /etc/ssh/sshd_config || echo 'KbdInteractiveAuthentication yes' >> /etc/ssh/sshd_config
grep -q '^ChallengeResponseAuthentication yes' /etc/ssh/sshd_config || echo 'ChallengeResponseAuthentication yes' >> /etc/ssh/sshd_config
grep -q '^UsePAM yes' /etc/ssh/sshd_config || echo 'UsePAM yes' >> /etc/ssh/sshd_config

systemctl restart ssh || systemctl restart sshd

# MOTD
cat > /etc/motd <<EOF
Welcome to the X2Go Multi-User Desktop Lab
Users:
- user1
- user2
EOF

# App klasörü
mkdir -p /home/ubuntu/app

# docker-compose.yml
cat > /home/ubuntu/app/docker-compose.yml <<EOF
version: '3'
services:
  nodeapp:
    image: profers/aws-node-lab:v1
    container_name: node-app
    ports:
      - "80:3000"
    restart: always
EOF

# Compose up
cd /home/ubuntu/app
docker-compose up -d
chown -R ubuntu:ubuntu /home/ubuntu/app
