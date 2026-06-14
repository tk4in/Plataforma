#!/bin/bash

echo -e "\n\e[32mVerificando se os parâmetros vieram\e[0m"
if [ "$#" -eq 0 ]; then
    echo "Você deve informar o parâmetro --dns1 ou --dns2."
    exit 1
fi
echo -e "Instalando: $1"

echo -e "\n\e[32mInstalando dependências\e[0m"
apk add ipcalc fuse-exfat
#e2fsprogs dosfstools ntfs-3g 

echo -e "\n\e[32mCarregando as variáveis de configuração do config.env\e[0m"
mkdir -p /mnt/usb
modprobe fuse
mount -t exfat /dev/sdb1 /mnt/usb
export $(cat /mnt/usb/config.env | xargs)
umount -f /dev/sdb1
apk del fuse-exfat

if [ -z "$TK_SSH" ] || [ -z "$TK_DOM" ] || [ -z "$TK_IP" ] || [ -z "$TK_GW" ] || [ -z "$TK_USER" ] || [ -z "$TK_PASS" ]; then
   echo -e "\n\e[33mO arquivo config.env não foi encontrado no pendrive ou falta alguma variável"
   echo -e "Verifique se o pendrive está conectado e se o arquivo config.env existe.\e[0m"
   exit 1 # Sai do escript
fi
echo -e "OK"

echo -e "\n\e[32mProcessando os parâmetros\e[0m"
IP_MIN=$(ipcalc --minaddr "$TK_IP" | awk -F '=' '{print $2}')
IP_MASK=$(ipcalc -m "$TK_IP" | awk -F '=' '{print $2}')
IP_REV=$(ipcalc --reverse-dns "$TK_IP" | awk -F '=' '{print $2}')
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
apk del ipcalc
echo -e "OK"

echo -e "\n\e[32mInstalando o Firewall\e[0m"
apk add ufw ip6tables
ufw default deny incoming && ufw default allow outgoing
ufw allow 53/tcp
ufw allow 53/udp
ufw allow 3000/tcp
ufw allow ${TK_SSH}/tcp
yes | ufw enable

echo -e "\n\e[32mSetando fuso horário\e[0m"
apk add tzdata
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
echo "America/Sao_Paulo" > /etc/timezone
apk del tzdata
apk add chrony
rc-update add chronyd default
rc-service chronyd start

echo -e "\n\e[32mCriando o usuário\e[0m"
adduser ${TK_USER} <<EOF
${TK_PASS}
${TK_PASS}
EOF

echo -e "\n\e[32mInstalando o SSH na porta ${TK_SSH}\e[0m"
apk add openssh openssh-server
sed -i "s/#Port 22/Port ${TK_SSH}/g" /etc/ssh/sshd_config
rc-update add sshd default
/etc/init.d/sshd restart

echo -e "\n\e[32mInstalando o Node/NPM\e[0m"
apk add libstdc++
export NODE_VERSION="22.22.3"
wget https://unofficial-builds.nodejs.org/download/release/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64-musl.tar.gz
mkdir -p /usr/local/lib/nodejs
tar -xzf node-v${NODE_VERSION}-linux-x64-musl.tar.gz -C /usr/local/lib/nodejs
rm node-v${NODE_VERSION}-linux-x64-musl.tar.gz
echo -e "export PATH=/"$PATH:/usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-x64-musl/bin/"" >> /etc/profile
source /etc/profile

echo -e "\n\e[32mInstalando o Bind9\e[0m"
apk add bind
mkdir -p /etc/bind/zones
chown ${TK_USER}:named /etc/bind/zones
echo -e "options {
    directory \"/var/bind\";
    
    listen-on { any; };
    listen-on-v6 { any; };

    allow-query { any; };
    allow-transfer { none; };

    pid-file \"/var/run/named/named.pid\";

    allow-recursion { none; };
    recursion no;
};

include \"/etc/bind/zones.conf\";" | tee /etc/bind/named.conf
echo -e "
zone \"${TK_DOM}\" IN {
    type master;
    file \"/etc/bind/zones/${TK_DOM}\";
};
zone \"${IP_REV}\" IN {
    type master;
    file \"/etc/bind/zones/rev.${TK_DOM}\";
}
" | tee /etc/bind/zones.conf
echo -e ";\$ORIGIN ${TK_DOM}.
;\$TTL 3600
@   IN SOA ns1.${TK_DOM}. hostmaster.${TK_DOM}. (
        1          ; serial (YYYYMMDDNN)
        3600       ; refresh
        900        ; retry
        1209600    ; expire
        300 )      ; negative cache
@    IN NS   ns1.${TK_DOM}.
@    IN NS   ns2.${TK_DOM}.
    
ns1  IN A    ${DNS1}
ns2  IN A    ${DNS2}
@    IN A    ${WEB1}

www  IN CNAME @
mail IN A     ${WEB1}
@    IN MX 10 mail.${TK_DOM}.

_txt IN TXT \"v=spf1 a mx ~all\"
_dmarc IN TXT \"v=DMARC1; p=none; rua=mailto:dmarc@${TK_DOM}\"" | tee /etc/bind/zones/${TK_DOM}
echo -e ";\$ORIGIN ${IP_REV}.
;\$TTL 3600
@   IN SOA ns1.${TK_DOM}. hostmaster.${TK_DOM}. (
        1          ; serial (YYYYMMDDNN)
        3600       ; refresh
        900        ; retry
        1209600    ; expire
        300 )      ; negative cache
    IN NS   ns1.${TK_DOM}.
    IN NS   ns2.${TK_DOM}.
10  IN PTR  ns1.${TK_DOM}.
11  IN PTR  ns2.${TK_DOM}.
20  IN PTR  ${TK_DOM}.
30  IN PTR  mail.${TK_DOM}." | tee /etc/bind/zones/rev.${TK_DOM}
rc-update add named
service named start

echo -e "\n\e[32mTunando o Alpine kernel\e[0m"
# Trocando mesagem de bem vindo
(
    echo  "Bem vindo ao servidor de DNS";
    echo;
) > /etc/motd;

# Liberar mais RAM para aceleração de rede
(
    echo  "net.core.rmem_default=31457280";
    echo  "net.core.wmem_default=31457280";
    echo  "net.core.rmem_max=134217728";
    echo  "net.core.wmem_max=134217728";
    echo  "net.core.netdev_max_backlog=250000";
    echo  "net.core.optmem_max=33554432";
    echo  "net.core.default_qdisc=fq";
    echo  "net.core.somaxconn=65535";
) > /etc/sysctl.d/051-net-core.conf;

# Aumentar capacidades de rede do protocolo TCP
(
    echo "net.ipv4.tcp_sack = 1";
    echo "net.ipv4.tcp_timestamps = 1";
    echo "net.ipv4.tcp_low_latency = 1";
    echo "net.ipv4.tcp_max_syn_backlog = 8192";
    echo "net.ipv4.tcp_rmem = 4096 87380 67108864";
    echo "net.ipv4.tcp_wmem = 4096 65536 67108864";
    echo "net.ipv4.tcp_mem = 6672016 6682016 7185248";
    echo "net.ipv4.tcp_congestion_control=htcp";
    echo "net.ipv4.tcp_mtu_probing=1";
    echo "net.ipv4.tcp_moderate_rcvbuf =1";
    echo "net.ipv4.tcp_no_metrics_save = 1";
) > /etc/sysctl.d/052-net-tcp-ipv4.conf;

# Ativar TCP-Fast-Open
(
    echo  "net.ipv4.tcp_fastopen=3";
) > /etc/sysctl.d/053-tcp-fast-open.conf;

# Ativar TCP-KeepAlive
(
    echo  "net.ipv4.tcp_keepalive_probes=9";
    echo  "net.ipv4.tcp_keepalive_intvl=75";
    echo  "net.ipv4.tcp_keepalive_time=7200";
) > /etc/sysctl.d/054-tcp-keepalive.conf;

# TTL padrão dos pacotes IPv4
(
    echo "net.ipv4.ip_default_ttl=128";
) > /etc/sysctl.d/062-default-ttl-ipv4.conf;

# Ajustes de ARP e fragmentacao (maior capacidade) - IPv4
(
    echo "net.ipv4.neigh.default.gc_interval = 30";
    echo "net.ipv4.neigh.default.gc_stale_time = 60";
    echo "net.ipv4.neigh.default.gc_thresh1 = 4096";
    echo "net.ipv4.neigh.default.gc_thresh2 = 8192";
    echo "net.ipv4.neigh.default.gc_thresh3 = 12288";
    echo;
    echo "net.ipv4.ipfrag_high_thresh=4194304";
    echo "net.ipv4.ipfrag_low_thresh=3145728";
    echo "net.ipv4.ipfrag_max_dist=64";
    echo "net.ipv4.ipfrag_secret_interval=0";
    echo "net.ipv4.ipfrag_time=30";
) > /etc/sysctl.d/063-neigh-ipv4.conf;

# Ajustes de ARP e fragmentacao (maior capacidade) - IPv6
(
    echo "net.ipv6.neigh.default.gc_interval = 30";
    echo "net.ipv6.neigh.default.gc_stale_time = 60";
    echo "net.ipv6.neigh.default.gc_thresh1 = 4096";
    echo "net.ipv6.neigh.default.gc_thresh2 = 8192";
    echo "net.ipv6.neigh.default.gc_thresh3 = 12288";
    echo;
    echo "net.ipv6.ip6frag_high_thresh=4194304";
    echo "net.ipv6.ip6frag_low_thresh=3145728";
    echo "net.ipv6.ip6frag_secret_interval=0";
    echo "net.ipv6.ip6frag_time=60";
) > /etc/sysctl.d/064-neigh-ipv6.conf;

# Ativar roteamento de pacotes IPv4
(
    echo  "net.ipv4.conf.default.forwarding=1"
) > /etc/sysctl.d/065-default-foward-ipv4.conf;

# Ativar roteamento de pacotes IPv6
(
    echo  "net.ipv6.conf.default.forwarding=1"
) > /etc/sysctl.d/066-default-foward-ipv6.conf;

# Ativar roteamento em todas as interfaces de rede
echo  "net.ipv4.conf.all.forwarding=1"   >  /etc/sysctl.d/067-all-foward-ipv4.conf
echo  "net.ipv6.conf.all.forwarding=1"   >  /etc/sysctl.d/068-all-foward-ipv6.conf
echo  "net.ipv4.ip_forward=1"            >  /etc/sysctl.d/069-ipv4-forward.conf

# Aumentar capacidades de arquivos abertos
(
    echo "fs.file-max=2097152";
    echo "fs.aio-max-nr=3263776";
    echo "fs.mount-max=1048576";
    echo "fs.mqueue.msg_max=128";
    echo "fs.mqueue.msgsize_max=131072";
    echo "fs.mqueue.queues_max=4096";
    echo "fs.pipe-max-size=8388608";
)  >  /etc/sysctl.d/072-fs-options.conf;

# Nao usar SWAP enquanto houver memoria RAM livre
echo  "vm.swappiness=0" > /etc/sysctl.d/073-swappiness.conf;

# Usar mais RAM para priorizar metadados de sistema de arquivos
echo  "vm.vfs_cache_pressure=50" > /etc/sysctl.d/074-vfs-cache-pressure.conf;

# Flush escrita mais rápido
(
    echo "vm.dirty_ratio=5";
    echo "vm.dirty_background_ratio=2";
) > /etc/sysctl.d/075-dirty.conf;

# Flexibilizar a alocacao de RAM para alem dos limites reais
echo  "vm.overcommit_memory=1" > /etc/sysctl.d/076-ram-overcommit.conf;

# Reiniciar o kernel apos 10 segundos em caso de pane geral
echo  "kernel.panic=10" > /etc/sysctl.d/081-kernel-panic.conf;

# Comando (sysctl -p) requer tudo em um unico arquivo:
(
    echo;
    cat /etc/sysctl.d/*.conf;
    echo;
) > /etc/sysctl.conf;

# Aplicar imediatamente:
sysctl -q --system 2>/dev/null;
sysctl -q -p 2>/dev/null;
echo -e "OK"

echo -e "\n\e[32mAlterando o HostName/IP\e[0m"
echo -e "${DNS_VAL}" | tee /etc/hostname
echo -e "127.0.0.1 localhost localhost.localdomain
${DNS_IP} ://${TK_DOM} ${DNS_VAL}
::1 localhost ip6-localhost ip6-loopback" | tee /etc/hosts
hostname -F /etc/hostname
echo -e "auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address ${DNS_IP}
    netmask ${IP_MASK}
    gateway ${TK_GW}" | tee /etc/network/interfaces
rc-service networking restart

trap 'rm -f "$0"' EXIT
