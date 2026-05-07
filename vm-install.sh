#!/bin/bash

helpFunction()
{
   echo -e "Use: $0 -u usuario -p password"
   echo -e "\t-u Usuario"
   echo -e "\t-p Senha do usuario"
   exit 1
}

while getopts u:p: opts; do
   case ${opts} in
      u) USER_VAL=${OPTARG} ;;
      p) PASS_VAL=${OPTARG} ;;
   esac
done

if [-z "$USER_VAL" ] || [ -z "$PASS_VAL" ]; then
   echo -e "\n\e[32mPreencha todos os parametros\e[0m";
   helpFunction.
fi

echo -e "\n\e[32mInstalando o Firewall\e[0m"
apt install -y ufw
ufw default deny incoming && ufw default allow outgoing
ufw allow 6922/tcp
yes | ufw enable

echo -e "\n\e[32mInstalando o SSH na porta 6922\e[0m"
apt install -y openssh-server
sed -i 's/#Port 22/Port 6922/g' /etc/ssh/sshd_config
systemctl daemon-reload
systemctl restart sshd

echo -e "\n\e[32mInstalando o Node/NPM\e[0m"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt update
apt install -y nodejs
npm install -g npm@11.11.0

echo -e "\n\e[32mInstalando o KVM\e[0m"
apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils libosinfo-bin virt-install virt-manager virt-viewer libguestfs-tools -y
usermod -a -G libvirt $USER_VAL
usermod -a -G kvm $USER_VAL
usermod -a -G adm $USER_VAL
usermod -a -G sudo $USER_VAL
chown -R $USER_VAL:$USER_VAL /var/lib/libvirt
systemctl enable libvirtd
systemctl start libvirtd
apt install libguestfs-tools virtinst -y
virsh net-start default
virsh net-autostart default

echo -e "\n\e[32mInstalando o ISO do Debian 13\e[0m"
cd /var/lib/libvirt/images
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso
virt-install \
  --name debian13.4.0 \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/debian13.4.0-base.qcow2,size=5,format=qcow2 \
  --location /var/lib/libvirt/images/debian-13.4.0-amd64-netinst.iso \
  --os-variant=debian13 \
  --network bridge=virbr0 \
  --graphics none \
  --console pty,target_type=serial \
  --extra-args='console=ttyS0,115200n8'
