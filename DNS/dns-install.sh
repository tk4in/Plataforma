#!/bin/bash

echo -e "\n\e[32mVerificando se os parâmetros vieram\e[0m"
if [ "$#" -eq 0 ]; then
    echo "Você deve informar o parâmetro --dns1 ou --dns2."
    exit 1
fi

echo -e "\n\e[32mInstalando dependências\e[0m"
apk add ipcalc fuse-exfat curl libstdc++
#e2fsprogs dosfstools ntfs-3g 

echo -e "\n\e[32mCarregando as variáveis de configuração do config.env\e[0m"
mkdir -p /mnt/usb
modprobe fuse
mount -t exfat /dev/sdb1 /mnt/usb
export $(cat /mnt/usb/config.env | xargs)
umount -f sdb1 

if [ -z "$SSH_PORT" ] || [ -z "$DOM_VAL" ] || [ -z "$IP_VAL" ] || [ -z "$GW_VAL" ] || [ -z "$USER_VAL" ] || [ -z "$PASS_VAL" ]; then
   echo "O arquivo config.env não foi encontrado no pendrive ou falta alguma variável"
   echo "Verifique se o pendrive está conectado e se o arquivo config.env existe."
   exit 1 # Sai do escript
fi

echo -e "\n\e[32mProcessando os parâmetros\e[0m"
IP_MIN=$(ipcalc --minaddr "$IP_VAL" | awk -F '=' '{print $2}')
IP_MASK=$(ipcalc -m "$IP_VAL" | awk -F '=' '{print $2}')
IFS=. read -r i1 i2 i3 i4 <<< "$IP_MIN"
DNS1="$i1.$i2.$i3.$((i4 + 2))"
DNS2="$i1.$i2.$i3.$((i4 + 3))"
WEB1="$i1.$i2.$i3.$((i4 + 4))"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dns1)
            DNS_VAL="ns1"
            DNS_IP=$DNS1
            shift 
            ;;
        --dns2)
            DNS_VAL="ns2"
            DNS_IP=$DNS2
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
ufw allow 3000/tcp
ufw allow ${SSH_PORT}/tcp
yes | ufw enable

echo -e "\n\e[32mCriando o usuário\e[0m"
adduser ${USER_VAL} <<EOF
${PASS_VAL}
${PASS_VAL}
EOF

echo -e "\n\e[32mInstalando o SSH na porta ${SSH_PORT}\e[0m"
apk add openssh openssh-server
sed -i "s/#Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
rc-update add sshd default
/etc/init.d/sshd restart

echo -e "\n\e[32mInstalando o Node/NPM\e[0m"
export NODE_VERSION="22.22.3"
wget https://unofficial-builds.nodejs.org/download/release/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64-musl.tar.gz
mkdir -p /usr/local/lib/nodejs
tar -xzf node-v$NODE_VERSION-linux-x64-musl.tar.gz -C /usr/local/lib/nodejs
echo -e 'export PATH=/usr/local/lib/nodejs/node-v$NODE_VERSION-linux-x64-musl/bin:$PATH' >> /etc/bash/bashrc
source /etc/bash/bashrc
rm node-v$NODE_VERSION-linux-x64-musl.tar.gz

echo -e "\n\e[32mInstalando o Bind9\e[0m"
apk add bind
mkdir -p /etc/bind/zones
chown $USER_VAL:named /etc/bind/zones
echo -e `options {
    directory "/var/bind"

    listen-on { ${DNS_IP}; };
    listen-on-v6 { none; };

    allow-transfer { none; };

    pid-file "/var/run/named/named.pid";
    
    allow-recursion { none; };
    recursion no;
};

zone "$DOM_VAL" IN {
    type master;
    file "/etc/bind/zones/$DOM_VAL";
};

include "/etc/bind/zones.conf";` | tee /etc/bind/named.conf
echo -e `\$TTL 3600
@   IN SOA dns1.$DOM_VAL. hostmaster.$DOM_VAL. (
        1          ; serial (YYYYMMDDNN)
        3600       ; refresh
        900        ; retry
        1209600    ; expire
        300 )      ; negative cache
    IN NS   ns1.$DOM_VAL.
    IN NS   ns2.$DOM_VAL.
    
ns1  IN A    $DNS1
ns2  IN A    $DNS2
@    IN A    $WEB1

www  IN CNAME @
mail IN A     $WEB1
@    IN MX 10 mail.$DOM_VAL.

_txt IN TXT "v=spf1 a mx ~all"
_dmarc IN TXT "v=DMARC1; p=none; rua=mailto:dmarc@$DOM_VAL"` | tee /etc/bind/zones/$DOM_VAL
rc-update add named
service named start

echo -e "\n\e[32mAlterando o HostName/IP\e[0m"
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

trap 'rm -f "$0"' EXIT
