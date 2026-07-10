#!/bin/bash

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

echo -e "\n\e[32mInstalando o Apache2\e[0m"
apk add apache2 openrc
mkdir -p /var/www/html/${TK_DOM}/report-to
chmod -R 755 /var/www/html/${TK_DOM}
chown -R apache:apache /var/www/html

mkdir -p /etc/apache2/sites-available
mkdir -p /etc/apache2/sites-enabled

echo "<VirtualHost *:80>
                ServerAdmin ${TK_USER}@${TK_DOM}
                ServerName ${TK_DOM}
                ServerAlias www.${TK_DOM}
                DocumentRoot /var/www/html/${TK_DOM}
                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/access.log combined
                <Directory /var/www/html/website>
                        Options Indexes FollowSymLinks
                        AllowOverride All
                        Require all granted
                </Directory>
		<IfModule mod_headers.c>
   			Header always set Strict-Transport-Security 'max-age=31536000; includeSubDomains'
			Header always set Reporting-Endpoints default='https://${TK_DOM}/report-to', csp-violation='https://${TK_DOM}/report-to'
			Header always set Content-Security-Policy default-src 'self'; report-to csp-violation
			Header unset X-Powered-By
		</IfModule>
</VirtualHost>" | tee /etc/apache2/sites-available/${TK_DOM}.conf
chown -R www-data:www-data /var/www/html/${TK_DOM}
wget -O /var/www/html/${TK_DOM}/report-to https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/WEB/report-to/index.php	 
a2enmod headers
a2dissite 000-default
a2ensite ${TK_DOM}
a2dismod mpm_prefork
a2enmod mpm_event http2
usermod -aG www-data ${TK_USER}


rc-update add apache2 default
rc-service apache2 start
echo "${TK_DOM}" | tee /var/www/html/${TK_DOM}/index.html

















































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
echo "OK"

echo -e "\n\e[32mAlterando o HostName/IP\e[0m"
echo -e "${HOST_NAME}" | tee /etc/hostname
echo -e "127.0.0.1 localhost localhost.localdomain
${WEB1} ://${TK_DOM} ${HOST_NAME}
::1 localhost ip6-localhost ip6-loopback" | tee /etc/hosts
hostname -F /etc/hostname
echo -e "auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address ${WEB1}
    netmask ${IP_MASK}
    gateway ${TK_GW}" | tee /etc/network/interfaces
echo -e "\n\e[32mReiniciando o servidor\e[0m"




echo -e "\n\e[32mInstalando dependências\e[0m"
apt install -y software-properties-common ca-certificates lsb-release apt-transport-https gnupg2
apt install -y nano curl wget git sed subversion alembic libjansson-dev autoconf automake libxml2-dev libncurses-dev libtool




echo -e "\n\e[32mInstalando o Apache2\e[0m"
apk add apache2
echo "<VirtualHost *:80>
                ServerAdmin ${USER_VAL}@${DOM_VAL}
                ServerName ${DOM_VAL}
                ServerAlias www.${DOM_VAL}
                DocumentRoot /var/www/html/${DOM_VAL}
                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/access.log combined
                <Directory /var/www/html/website>
                        Options Indexes FollowSymLinks
                        AllowOverride All
                        Require all granted
                </Directory>
		<IfModule mod_headers.c>
    			Header always set Strict-Transport-Security 'max-age=31536000; includeSubDomains'
			Header always set Reporting-Endpoints default='https://${DOM_VAL}/report-to', csp-violation='https://${DOM_VAL}/report-to'
			Header always set Content-Security-Policy default-src 'self'; report-to csp-violation
			Header unset X-Powered-By
		</IfModule>
</VirtualHost>" | tee /etc/apache2/sites-available/${DOM_VAL}.conf
chown -R www-data:www-data /var/www/html/${DOM_VAL}
mkdir -p /var/www/html/${DOM_VAL}/report-to
wget -O /var/www/html/${DOM_VAL}/report-to https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/WEB/report-to/index.php	 
a2enmod headers
a2dissite 000-default
a2ensite ${DOM_VAL}
a2dismod mpm_prefork
a2enmod mpm_event http2
usermod -aG www-data ${USER_VAL}
systemctl start apache2 && systemctl enable apache2
echo "${DOM_VAL}" | tee /var/www/html/${DOM_VAL}/index.html

echo -e "\n\e[32mInstalando Certificados SSL\e[0m"
apt install -y certbot python3-certbot-apache
yes | certbot --apache --agree-tos --redirect -d ${DOM_VAL} -d www.${DOM_VAL} -m ${USER_VAL}@${DOM_VAL}
certbot renew --dry-run
systemctl restart apache2

echo -e "\n\e[32mInstalando o PHP\e[0m"
add-apt-repository ppa:ondrej/php -y
apt -y update
apt install -y php8.4 libapache2-mod-php8.4
apt install -y php8.4-{bcmath,enchant,mysql,curl,dba,gd,mbstring,mcrypt,odbc,opcache,pgsql,sqlite3,pspell,soap,tidy,xml,xmlrpc,xsl,zip} 
apt install -y php8.4-fpm
a2enmod proxy_fcgi setenvif
a2enconf php8.4-fpm     
systemctl start php8.4-fpm && systemctl enable php8.4-fpm
systemctl restart apache2
echo "<?php phpinfo();?>" | tee /var/www/html/${DOM_VAL}/phpinfo.php

echo -e "\n\e[32mInstalando o MariaDB\e[0m"
apt install -y mariadb-server mariadb-client
mysql_install_db --user=mysql --ldata=/var/lib/mysql
systemctl start mariadb && systemctl enable mariadb
mariadb-secure-installation <<EOF

y
y
${PASS_VAL}
${PASS_VAL}
y
y
y
y
EOF

echo -e "\n\e[32mInstalando postfix (E-mail)\e[0m"
{ echo -e "\n"; echo -e "${DOM_VAL}\n"; } | apt install -y postfix postfix-mysql
apt install -y postfix-policyd-spf-python
echo "#policyd-spf
policyd-spf  unix  -       n       n       -       0       spawn
  user=policyd-spf argv=/usr/bin/policyd-spf" | tee -a /etc/postfix/master.cf
echo "#policyd-spf
policyd-spf_time_limit = 3600
smtpd_recipient_restrictions =
  permit_mynetworks,
  permit_sasl_authenticated,
  reject_unauth_destination,
  check_policy_service unix:private/policyd-spf" | tee -a /etc/postfix/main.cf
echo "#Submission Service
submission     inet     n    -    y    -    -    smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_tls_wrappermode=no
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
#Microsoft Outlook Support
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth" | tee -a /etc/postfix/master.cf
postconf -e "smtpd_tls_cert_file=/etc/letsencrypt/live/${DOM_VAL}/fullchain.pem"
postconf -e "smtpd_tls_key_file=/etc/letsencrypt/live/${DOM_VAL}/privkey.pem"
postconf -e "smtpd_use_tls=yes"
postconf -e "smtpd_tls_security_level=may"
postconf -e "smtp_tls_security_level=may"
postconf -e "mailbox_size_limit=25600000"
postconf -e "smtp_tls_loglevel=1"
echo "#Enforce TLSv1.3 or TLSv1.2
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1" | tee -a /etc/postfix/main.cf
systemctl restart postfix

echo -e "\n\e[32mInstalando DKIM (E-mail)\e[0m"
apt install -y opendkim opendkim-tools
gpasswd -a postfix opendkim
sed -i 's/#Mode/Mode/g' /etc/opendkim.conf
sed -i 's/#SubDomains/SubDomains/g' /etc/opendkim.conf
echo "LogWhy  yes
AutoRestart  yes
AutoRestartRate  10/1M
Background  yes
DNSTimeout  5
SignatureAlgorithm  rsa-sha256
KeyTable  refile:/etc/opendkim/key.table
SigningTable  refile:/etc/opendkim/signing.table
ExternalIgnoreList  /etc/opendkim/trusted.hosts
InternalHosts  /etc/opendkim/trusted.hosts" | tee -a /etc/opendkim.conf
mkdir -p /etc/opendkim/keys
chown -R opendkim:opendkim /etc/opendkim
chmod go-rw /etc/opendkim/keys
echo "*@${DOM_VAL} default._domainkey.${DOM_VAL}
*@*.${DOM_VAL} default._domainkey.${DOM_VAL}" | tee /etc/opendkim/signing.table
echo "default._domainkey.${DOM_VAL}     ${DOM_VAL}:default:/etc/opendkim/keys/${DOM_VAL}/default.private" | tee /etc/opendkim/key.table
echo "127.0.0.1
localhost
.${DOM_VAL}" | tee /etc/opendkim/trusted.hosts
mkdir -p /etc/opendkim/keys/${DOM_VAL}
opendkim-genkey -b 2048 -d ${DOM_VAL} -D /etc/opendkim/keys/${DOM_VAL} -s default -v
chown opendkim:opendkim /etc/opendkim/keys/${DOM_VAL}/default.private
chmod 600 /etc/opendkim/keys/${DOM_VAL}/default.private
service opendkim restart
mkdir /var/spool/postfix/opendkim
chown opendkim:postfix /var/spool/postfix/opendkim
sed -i 's/Socket/#Socket/g' /etc/opendkim.conf
echo "Socket    local:/var/spool/postfix/opendkim/opendkim.sock" | tee -a /etc/opendkim.conf
sed -i 's/SOCKET/#SOCKET/g' /etc/default/opendkim
echo "SOCKET=local:/var/spool/postfix/opendkim/opendkim.sock" | tee -a /etc/default/opendkim
echo '# Milter configuration
milter_default_action = accept
milter_protocol = 6
smtpd_milters = local:opendkim/opendkim.sock
non_smtpd_milters = $smtpd_milters' | tee -a /etc/postfix/main.cf
usermod -aG opendkim ${USER_VAL}
service opendkim restart
service postfix restart

echo -e "\n\e[32mInstalando o Adminer\e[0m"
mkdir -p /var/www/html/${DOM_VAL}/adminer
chown -R www-data: /var/www/html/${DOM_VAL}/adminer
wget -O /var/www/html/${DOM_VAL}/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v5.4.1/adminer-5.4.1-mysql-en.php

echo -e "\n\e[32mCriando o Banco de Dados do Maindb\e[0m"
mariadb <<EOF
CREATE DATABASE maindb;
CREATE USER '${USER_VAL}'@'%' IDENTIFIED BY '${PASS_VAL}';
GRANT ALL ON maindb.* TO '${USER_VAL}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
CREATE TABLE `chipstk` (
  `msisdn` varchar(13) NOT NULL,
  `lid` varchar(32) NOT NULL,
  `linetype` varchar(6) NOT NULL,
  `dateactive` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `dateblock` timestamp NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `dateunblock` timestamp NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `status` varchar(16) NOT NULL,
  `custo` float(6,2) unsigned DEFAULT NULL,
  `mbqt` int(5) unsigned DEFAULT NULL,
  `mbs` varchar(2) DEFAULT NULL,
  `owner` varchar(25) DEFAULT NULL,
  PRIMARY KEY (`msisdn`),
  UNIQUE KEY `lid` (`lid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf32 COLLATE=utf32_general_ci;
CREATE TABLE `syslog` (
  `data` datetime NOT NULL,
  `app` varchar(20) NOT NULL,
  `channel` varchar(128) NOT NULL,
  `devices` int(6) NOT NULL,
  `msgsin` int(6) NOT NULL,
  `msgsout` int(6) NOT NULL,
  `bytsin` int(6) NOT NULL,
  `bytsout` int(6) NOT NULL,
  PRIMARY KEY (`data`,`app`)
) ENGINE=InnoDB DEFAULT CHARSET=utf32 COLLATE=utf32_general_ci;
EXIT
EOF
