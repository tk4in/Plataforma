#!/bin/bash

# Atualizar a lista de pacotes e o sistema
echo "Atualizando o sistema..."
sudo su
apt update -y && apt upgrade -y
apt install -y gnupg apt-transport-https ca-certificates
apt install -y nano curl wget git sed subversion alembic libjansson-dev autoconf automake libxml2-dev libncurses-dev libtool

# Instalando o Firewall
echo "Instalando o Firewall"
apt install ufw
ufw default deny incoming && ufw default allow outgoing
ufw allow https
ufw allow 3306
ufw allow 6922
ufw allow http
ufw enable

# Alterando a porta do SSH
echo "Alterando a porta do SSH"
sed -i 's/#Port 22/Port 6922/g' /etc/ssh/sshd_config
systemctl restart ssh

# Instalando o Node/NPM
echo "Instalando o Node/NPM"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt update
apt install -y nodejs
npm install -g npm@latest
