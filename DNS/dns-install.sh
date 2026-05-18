#!/bin/bash

echo -e "\n\e[32mVerificando se os parâmetros vieram\e[0m"
if [ "$#" -eq 0 ]; then
    echo "Você deve informar o parâmetro --dns1 ou --dns2."
    exit 1
fi

echo -e "\n\e[32mInstalando dependências\e[0m"
apk add ipcalc e2fsprogs dosfstools ntfs-3g fuse-exfat

echo -e "\n\e[32mCarregando as variáveis de configuração do config.env\e[0m"
mkdir -p /mnt/usb
modprobe fuse
mount -t exfat /dev/sdb1 /mnt/usb
export $(cat /mnt/usb/config.env | xargs)

if [ -z "$SSH_PORT" ] || [ -z "$DOM_VAL" ] || [ -z "$IP_VAL" ] || [ -z "$GW_VAL" ] || [ -z "$USER_VAL" ] || [ -z "$PASS_VAL" ]; then
   echo "O arquivo config.env não foi encontrado no pendrive ou falta alguma variável"
   echo "Verifique se o pendrive está conectado e se o arquivo config.env existe."
   exit 1 # Sai do escript
fi

echo -e "\n\e[32mProcessando os parâmetros\e[0m"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dns1)
            DNS_VAL="dns1"
            IP_MIN=$(ipcalc --minaddr "$IP_VAL" | awk -F '=' '{print $2}')
            IP_MASK=$(ipcalc -m "$IP_VAL" | awk -F '=' '{print $2}')
            IFS=. read -r i1 i2 i3 i4 <<< "$IP_MIN"
            DNS_IP="$i1.$i2.$i3.$((i4 + 2))"
            shift 
            ;;
        --dns2)
            DNS_VAL="dns2"
            IP_MIN=$(ipcalc --minaddr "$IP_VAL" | awk -F '=' '{print $2}')
            IP_MASK=$(ipcalc -m "$IP_VAL" | awk -F '=' '{print $2}')
            IFS=. read -r i1 i2 i3 i4 <<< "$IP_MIN"
            DNS_IP="$i1.$i2.$i3.$((i4 + 3))"
            shift 
            ;;
        *)
            echo "Você deve informar o parâmetro --dns1 ou --dns2."
            shift 
            exit 1
            ;;
    esac
done

echo -e "\n\e[32mInstalando o Firewall\e[0m"
apk add ufw ip6tables
ufw default deny incoming && ufw default allow outgoing
ufw allow 53/tcp
ufw allow 53/udp
ufw allow ${SSH_PORT}/tcp
yes | ufw enable

echo -e "\n\e[32mAlterando o HostName/IP/DNS\e[0m"
echo -e "${DNS_VAL}" | tee /etc/hostname
echo -e "127.0.0.1 localhost localhost.localdomain
${DNS_IP} ://${DOM_VAL} ${DNS_VAL}
::1 localhost ip6-localhost ip6-loopback" | tee /etc/hosts
hostname -F /etc/hostname
echo -e "auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address ${DNS_IP}
    netmask ${IP_MASK}
    gateway ${GW_VAL}" | tee /etc/network/interfaces
rc-service networking restart

echo -e "\n\e[32mAlterando o IP\e[0m"
echo -e "${DNS_VAL}" | tee /etc/hostname
echo -e "127.0.0.1 localhost localhost.localdomain
${DNS_IP} ://${DOM_VAL} ${DNS_VAL}
::1 localhost ip6-localhost ip6-loopback" | tee /etc/hosts

echo -e "\n\e[32mCriando o usuário\e[0m"
adduser ${USER_VAL} <<EOF
${PASS_VAL}
${PASS_VAL}
EOF

echo -e "\n\e[32mInstalando o SSH na porta ${SSH_PORT}\e[0m"
apk add openssh
sed -i "s/#Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
rc-update add sshd
/etc/init.d/sshd restart

echo -e "\n\e[32mInstalando o Node/NPM\e[0m"
apk add nodejs npm

echo -e "\n\e[32mInstalando o Bind9\e[0m"
apk add bind

