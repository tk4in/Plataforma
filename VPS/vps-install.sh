#!/bin/bash

trap 'rm -f "$0"' EXIT

helpFunction()
{
   echo -e "Use: $0 -u usuario -p password"
   echo -e "\t-u Usuário"
   echo -e "\t-p Senha do usuário"
   exit 1
}

while getopts u:p: opts; do
   case ${opts} in
      u) USER_VAL=${OPTARG} ;;
      p) PASS_VAL=${OPTARG} ;;
   esac
done

if [ -z "$USER_VAL" ] || [ -z "$PASS_VAL" ]; then
   echo -e "\n\e[32mPreencha todos os parâmetros\e[0m";
   helpFunction
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
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/vm-template.sh
chmod +x vm-template.sh
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/vm-template_a.sh
chmod +x vm-template_a.sh
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/vm-clone.sh
chmod +x vm-clone.sh
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/vm-stop.sh
chmod +x vm-stop.sh
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/vm-start.sh
chmod +x vm-start.sh
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/vm-remove.sh
chmod +x vm-remove.sh

echo -e "\n\e[32mInstalando o Node/NPM\e[0m"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt update
apt install -y nodejs
npm install -g npm@11.11.0

echo -e "\n\e[32mInstalando o KVM\e[0m"
apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils libosinfo-bin virt-install virt-manager virtinst libguestfs-tools
usermod -a -G libvirt-qemu $USER_VAL
usermod -a -G kvm $USER_VAL
chown -R $USER_VAL:$USER_VAL /var/lib/libvirt
systemctl enable libvirtd
systemctl start libvirtd
virsh net-autostart default
virsh net-start default

echo -e "\n\e[32mBaixando o ISO do Debian 13\e[0m"
wget -P /var/lib/libvirt/images https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso
wget -O /var/lib/libvirt/images/preseed.cfg https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/preseed-debian-13.cfg	 

echo -e "\n\e[32mCriando template 'Debian 13.4.0-2-2048-5'\e[0m"
systemctl restart libvirtd
~/vm-template.sh "debian-13.4.0" "2" "2048" "5" "debian-13.4.0-amd64-netinst.iso" "debian13" &
PID=$!
wait $PID

echo -e "\n\e[32mRemovendo arquivos temporarios\e[0m"
rm -rf /var/lib/libvirt/images/debian-13.4.0-amd64-netinst.iso
rm -rf /var/lib/libvirt/images/preseed.cfg

#echo -e "\n\e[32mInstalando o ISO do Alpine 3\e[0m"
#wget -P /var/lib/libvirt/images https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-virt-3.23.4-x86_64.iso
#wget -P /var/lib/libvirt/images https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-standard-3.23.4-x86_64.iso
#wget -O https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/preseed-debian-13.cfg

#echo -e "\n\e[32mCriando template 'Alpine 3.23.4-2-2048-5'\e[0m"
#systemctl restart libvirtd
#~/vm-template_a.sh "Alpine-3.23.4" "2" "2048" "5" "alpine-virt-3.23.4-x86_64.iso" "alpinelinux3.21" &
#PID=$!
#wait $PID

#echo -e "\n\e[32mRemovendo arquivos temporarios\e[0m"
#rm -rf /var/lib/libvirt/images/alpine-standard-3.23.4-x86_64.iso
#rm -rf /var/lib/libvirt/images/preseed.cfg

virsh list --all
