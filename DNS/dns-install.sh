#!/bin/bash

echo -e "\n\e[32mCarrega as variáveis de configuração\e[0m"
mkdir -p /mnt/usb
mount -t vfat /dev/sdb1 /mnt/usb
export $(cat /mnt/usb/config.env | xargs)

if [ -z "$SSH_PORT" ] || [ -z "$DOM_VAL" ] || [ -z "$IP_VAL" ] || [ -z "$GW_VAL" ] || [ -z "$USER_VAL" ] || [ -z "$PASS_VAL" ]; then
   echo -e "O arquivo config.env não foi encontrado no pendrive ou falta alguma variável"
   echo -e "Verifique se o pendrive esta conectado e se o arquivo config.env existe."
   exit 1 # Sai do escript
fi

if [ -z "$dns1" ] && [ -z "$dns2" ]; then
   echo -e "Você deve informar o parâmetro --dns1 ou --dns2."
   exit 1
fi

echo -e "\n\e[32mInstalando dependencias\e[0m"
apk add ipcalc

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dns1)
            DNS_VAL="dns1"
            IP_MIN=$(ipcalc -n "$IP_VAL" | grep HostMin | awk '{print $2}')
            IFS=. read -r i1 i2 i3 i4 <<< "$IP_MIN"
            DNS_IP="$i1.$i2.$i3.$((i4 + 2))"
            ;;
        --dns2)
            DNS_VAL="dns2"
            IP_MIN=$(ipcalc -n "$IP_VAL" | grep HostMin | awk '{print $2}')
            IFS=. read -r i1 i2 i3 i4 <<< "$IP_MIN"
            DNS_IP="$i1.$i2.$i3.$((i4 + 3))"
            ;;
        *)
            echo -e "Você deve informar o parâmetro --dns1 ou --dns2."
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

echo -e "\n\e[32mAlterando o HostName\e[0m"
echo -e "${DNS_VAL}" | tee /etc/hostname
echo -e "127.0.0.1 localhost localhost.localdomain
${DNS_IP} ://${DOM_VAL} ${DNS_VAL}
::1 localhost ip6-localhost ip6-loopback" | tee /etc/hosts
hostname -F /etc/hostname

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

echo -e "\n\e[32mInstalando o End Point pra o DNS\e[0m"
mkdir -p /home/${USER_VAL}/epdns
wget -r -np -nH -O /var/home/${DOM_VAL}/epdns https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/DNS/epdns
