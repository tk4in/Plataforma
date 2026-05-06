#!/bin/bash

echo -e "\n\e[32mInstalando o Firewall\e[0m"
apt install -y ufw
ufw default deny incoming && ufw default allow outgoing
ufw allow 6922/tcp
yes | ufw enable

echo -e "\n\e[32mInstalando o SSH na porta 6922\e[0m"
apt install openssh-server -y
sed -i 's/#Port 22/Port 6922/g' /etc/ssh/sshd_config
systemctl daemon-reload
systemctl restart sshd

echo -e "\n\e[32mInstalando o KVM\e[0m"
apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager

