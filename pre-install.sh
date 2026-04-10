#!/bin/bash

helpFunction()
{
   echo "\nUsage: $0 -d dominio -u usuario -p password"
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

if [ -z "$DOM_VAL" ] || [ -z "$USER_VAL" ] || [ -z "$PASS_VAL" ]
then
   echo "Preencha todos os parametros";
   helpFunction
fi

echo -e "\n\e[32mInstalando dependencias\e[0m"
apt install -y software-properties-common ca-certificates lsb-release apt-transport-https gnupg2
apt install -y nano curl wget git sed subversion alembic libjansson-dev autoconf automake libxml2-dev libncurses-dev libtool
yes | apt autoremove

echo -e "\n\e[32mAlterando o HostName\e[0m"
hostnamectl set-hostname server.${DOM_VAL}
echo server.${DOM_VAL}

echo -e "\n\e[32mInstalando o Firewall\e[0m"
apt install ufw
ufw default deny incoming && ufw default allow outgoing
ufw allow 80,443/tcp
ufw allow 25,143,587/tcp
ufw allow 3306/tcp
ufw allow 6922/tcp
yes | ufw enable

echo -e "\n\e[32mAlterando a porta do SSH\e[0m"
sed -i 's/#Port 22/Port 6922/g' /etc/ssh/sshd_config
systemctl daemon-reload
systemctl restart ssh.socket

echo -e "\n\e[32mInstalando Servidor de e-mail\e[0m"
yes | apt install postfix
yes | apt install dovecot-imapd dovecot-pop3d

echo -e "\n\e[32mInstalando o Apache2\e[0m"
apt install -y apache2
echo "<VirtualHost *:80>
		ServerAdmin admin@${DOM_VAL}
		ServerName www.${DOM_VAL}
		DocumentRoot /var/www/html${DOM_VAL}
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
systemctl enable apache2

echo -e "\n\e[32mInstalando o Certificado HTTPS\e[0m"
apt install -y certbot python3-certbot-apache
yes | certbot --apache --agree-tos --redirect -d ${DOM_VAL} -d www.${DOM_VAL} -m admin@${DOM_VAL}
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
systemctl enable php8.4-fpm     
systemctl start php8.4-fpm
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

echo -e "\n\e[32mCriando o Banco de Dados\e[0m"
mariadb <<EOF
CREATE DATABASE maindb;
CREATE USER 'userdb'@'localhost' IDENTIFIED BY '${PASS_VAL}';
GRANT ALL ON maindb.* TO 'userdb'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
EOF

echo -e "\n\e[32mInstalando o Adminer\e[0m"
mkdir -p /var/www/html/${DOM_VAL}/adminer
cd /var/www/html/${DOM_VAL}/adminer
wget https://github.com/vrana/adminer/releases/download/v5.4.1/adminer-5.4.1-mysql-en.php
mv adminer-5.4.1-mysql-en.php adminer.php

echo -e "\n\e[32mInstalando o Node/NPM\e[0m"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt update
apt install -y nodejs
npm install -g npm@latest
