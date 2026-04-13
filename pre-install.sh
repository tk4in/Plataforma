#!/bin/bash

helpFunction()
{
   echo -e "Usage: $0 -d dominio -u usuario -p password"
   echo -e "\t-d Dominio do site"
   echo -e "\t-u Usuario"
   echo -e "\t-p Senha do usuario"
   exit 1 # Exit script after printing help
}

while getopts d:u:p: opts; do
   case ${opts} in
      d) DOM_VAL=${OPTARG} ;;
      u) USER_VAL=${OPTARG} ;;
      p) PASS_VAL=${OPTARG} ;;
   esac
done

if [ -z "$DOM_VAL" ] || [ -z "$USER_VAL" ] || [ -z "$PASS_VAL" ]; then
   echo -e "\n\e[32mPreencha todos os parametros\e[0m";
   helpFunction
fi

echo -e "\n\e[32mInstalando dependencias\e[0m"
apt install -y software-properties-common ca-certificates lsb-release apt-transport-https gnupg2
apt install -y nano curl wget git sed subversion alembic libjansson-dev autoconf automake libxml2-dev libncurses-dev libtool

echo -e "\n\e[32mAlterando o HostName\e[0m"
hostnamectl set-hostname ${DOM_VAL}
echo "${DOM_VAL}"

echo -e "\n\e[32mInstalando o Firewall\e[0m"
apt install ufw
ufw default deny incoming && ufw default allow outgoing
ufw allow 80,443/tcp
ufw allow 25,587,465,143,993/tcp
ufw allow 110,995/tcp
ufw allow 3306/tcp
ufw allow 6922/tcp
yes | ufw enable

echo -e "\n\e[32mAlterando a porta do SSH\e[0m"
sed -i 's/#Port 22/Port 6922/g' /etc/ssh/sshd_config
systemctl daemon-reload
systemctl restart ssh.socket
echo "Port: 6922"

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
</VirtualHost>" | tee /etc/apache2/sites-available/${DOM_VAL}.conf
mkdir -p /var/www/html/${DOM_VAL}
chown -R www-data:www-data /var/www/html/${DOM_VAL}
a2dissite 000-default
a2ensite ${DOM_VAL}
a2dismod mpm_prefork
a2enmod mpm_event http2
systemctl start apache2 && systemctl enable apache2 

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
cd /var/www/html/${DOM_VAL}
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/htaccess
sed -i 's/xxxxxxxx/tk4in.com/g' ./htaccess
mv htaccess .htaccess
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

echo -e "\n\e[32mInstalando o Adminer\e[0m"
mkdir -p /var/www/html/${DOM_VAL}/adminer
chown -R www-data: /var/www/html/${DOM_VAL}/adminer
cd /var/www/html/${DOM_VAL}/adminer
wget https://github.com/vrana/adminer/releases/download/v5.4.1/adminer-5.4.1-mysql-en.php
mv adminer-5.4.1-mysql-en.php adminer.php

echo -e "\n\e[32mInstalando postfix (E-mail)\e[0m"
{ echo -e "\n"; echo -e "${DOM_VAL}\n"; } | apt install -y postfix 
apt install -y postfix-mysql postfix-policyd-spf-python
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
postconf -e "mailbox_size_limit=256000000"
postconf -e "smtp_tls_loglevel=1"
echo "#Enforce TLSv1.3 or TLSv1.2
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1" | tee -a /etc/postfix/main.cf
systemctl restart postfix
