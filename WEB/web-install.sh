#!/bin/bash

helpFunction()
{
   echo -e "Use: $0 -d dominio -i ip -g gateway -u usuario -p password"
   echo -e "\t-d Dominio do site"
   echo -e "\t-i IP"
   echo -e "\t-g gateway"
   echo -e "\t-u Usuário"
   echo -e "\t-p Senha do usuário"
   exit 1 # Exit script after printing help
}

while getopts d:i:g:u:p: opts; do
   case ${opts} in
      d) DOM_VAL=${OPTARG} ;;
      i) IP_VAL=${OPTARG} ;;
      g) GW_VAL=${OPTARG} ;;
      u) USER_VAL=${OPTARG} ;;
      p) PASS_VAL=${OPTARG} ;;
   esac
done

if [ -z "$DOM_VAL" ] || [ -z "$IP_VAL" ] || [ -z "$GW_VAL" ] || [ -z "$USER_VAL" ] || [ -z "$PASS_VAL" ]; then
   echo -e "\n\e[32mPreencha todos os parâmetros\e[0m";
   helpFunction
fi

echo -e "\n\e[32mInstalando dependências\e[0m"
apt install -y software-properties-common ca-certificates lsb-release apt-transport-https gnupg2
apt install -y nano curl wget git sed subversion alembic libjansson-dev autoconf automake libxml2-dev libncurses-dev libtool

echo -e "\n\e[32mInstalando o Firewall\e[0m"
apt install ufw
ufw default deny incoming && ufw default allow outgoing
ufw allow 80,443/tcp
ufw allow 25,587,465,143,993/tcp
ufw allow 110,995/tcp
ufw allow 3306/tcp
ufw allow 6922/tcp
yes | ufw enable

echo -e "\n\e[32mAlterando o HostName\e[0m"
hostnamectl set-hostname ${DOM_VAL}
echo "${DOM_VAL}"

echo -e "\n\e[32mCriando o usuário\e[0m"
useradd ${USER_VAL} -c "Usuario" -s /bin/bash -m -p $(openssl passwd ${PASS_VAL})

echo -e "\n\e[32mInstalando o SSH na porta 6922\e[0m"
apt install -y openssh-server
sed -i 's/#Port 22/Port 6922/g' /etc/ssh/sshd_config
systemctl daemon-reload
systemctl restart ssh.socket

echo -e "\n\e[32mInstalando o Node/NPM\e[0m"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt update
apt install -y nodejs
npm install -g npm@11.11.0

echo -e "\n\e[32mInstalando o Apache2\e[0m"
apt install -y apache2
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
