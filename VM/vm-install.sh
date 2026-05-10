#!/bin/bash

trap 'rm -f "$0"' EXIT

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

echo -e "\n\e[32mBaixando scripts\e[0m"
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/vm/vm-template.sh
chmod +x vm-template.sh
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/vm/vm-clone.sh
chmod +x vm-clone.sh

echo -e "\n\e[32mInstalando o Node/NPM\e[0m"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt update
apt install -y nodejs
npm install -g npm@11.11.0

echo -e "\n\e[32mInstalando o KVM\e[0m"
apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils libosinfo-bin virt-install virt-manager virtinst libguestfs-tools
usermod -a -G libvirt $USER_VAL
usermod -a -G kvm $USER_VAL
usermod -a -G adm $USER_VAL
usermod -a -G sudo $USER_VAL
chown -R $USER_VAL:$USER_VAL /var/lib/libvirt
systemctl enable libvirtd
systemctl start libvirtd
virsh net-autostart default
virsh net-start default

cd /var/lib/libvirt/images
echo -e "\n\e[32mInstalando o ISO do Debian 13\e[0m"
systemctl restart libvirtd
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/vm/preseed-debian-13.cfg	
mv /var/lib/libvirt/images/preseed-debian-13.cfg /var/lib/libvirt/images/preseed.cfg
echo -e "\n\e[32mCriando template 'Debian 13.4.0-2-2048-5'\e[0m"
~/vm-template.sh "debian-13.4.0" "2" "2048" "5" "debian-13.4.0-amd64-netinst.iso" "debian13" &
PID=$!
wait $PID

rm -rf /var/lib/libvirt/images/debian-13.4.0-amd64-netinst.iso
rm -rf /var/lib/libvirt/images/preseed.cfg
	
