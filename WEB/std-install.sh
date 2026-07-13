echo -e "Instalando: WEB1"

echo -e "\n\e[32mCarregando as variáveis de configuração do config.env\e[0m"
apk add fuse-exfat
mkdir -p /mnt/usb
modprobe fuse
mount -t exfat /dev/sdb1 /mnt/usb
export $(cat /mnt/usb/config.env | xargs)
umount -f /dev/sdb1
apk del fuse-exfat

if [ -z "$TK_SSH" ] || [ -z "$TK_DOM" ] || [ -z "$TK_IP" ] || [ -z "$TK_GW" ] || [ -z "$TK_USER" ] || [ -z "$TK_PASS" ]; then
   echo -e "\n\e[33mO arquivo config.env não foi encontrado no pendrive ou falta alguma variável"
   echo -e "Verifique se o pendrive está conectado e se o arquivo config.env existe.\e[0m"
   exit 1
fi

echo -e "\n\e[32mInstalando o Firewall\e[0m"
apk add ufw ip6tables
ufw default deny incoming && ufw default allow outgoing
ufw allow 80,443/tcp
ufw allow 25,587,465,143,993/tcp
ufw allow 110,995/tcp
ufw allow 3306/tcp
ufw allow ${TK_SSH}/tcp
yes | ufw enable

echo -e "\n\e[32mSetando fuso horário\e[0m"
apk add tzdata
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
echo "export TZ=America/Sao_Paulo" >> /etc/profile
echo "America/Sao_Paulo" > /etc/timezone
apk add chrony
rc-update add chronyd default
rc-service chronyd start

echo -e "\n\e[32mCriando o usuário\e[0m"
addgroup ${TK_USER}
adduser -G ${TK_USER} ${TK_USER} <<EOF
${TK_PASS}
${TK_PASS}
EOF

echo -e "\n\e[32mInstalando o SSH na porta ${TK_SSH}\e[0m"
apk add openssh openssh-server
sed -i "s/#Port 22/Port ${TK_SSH}/g" /etc/ssh/sshd_config
rc-update add sshd default
/etc/init.d/sshd restart

echo -e "\n\e[32mInstalando o Node/NPM\e[0m"
apk add libstdc++ git
export NODE_VERSION="22.23.1"
wget https://unofficial-builds.nodejs.org/download/release/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64-musl.tar.gz
mkdir -p /usr/local/lib/nodejs
tar -xzf node-v${NODE_VERSION}-linux-x64-musl.tar.gz -C /usr/local/lib/nodejs
rm node-v${NODE_VERSION}-linux-x64-musl.tar.gz
echo -e "export PATH=\"$PATH:/usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-x64-musl/bin\"" >> /etc/profile
source /etc/profile

echo -e "\n\e[32mProcessando os parâmetros para o WEB1\e[0m"
apk add ipcalc
IP_MIN=$(ipcalc --minaddr "$TK_IP" | awk -F '=' '{print $2}')
IP_MASK=$(ipcalc -m "$TK_IP" | awk -F '=' '{print $2}')
IP_REV=$(ipcalc --reverse-dns "$TK_IP" | awk -F '=' '{print $2}')
IFS=. read -r i1 i2 i3 i4 <<< "$IP_MIN"
DNS1="$i1.$i2.$i3.$((i4 + 2))"
DNS2="$i1.$i2.$i3.$((i4 + 3))"
WEB1="$i1.$i2.$i3.$((i4 + 4))"
HOST_NAME="web1"
apk del ipcalc
