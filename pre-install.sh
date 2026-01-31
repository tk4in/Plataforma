#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -d dominio -u usuario -p password"
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

# Atualizar a lista de pacotes e o sistema
echo ""
echo "Atualizando o sistema..."
apt update -y && apt upgrade -y
apt install -y gnupg apt-transport-https ca-certificates
apt install -y nano curl wget git sed subversion alembic libjansson-dev autoconf automake libxml2-dev libncurses-dev libtool

# Instalando o Firewall
echo ""
echo "Instalando o Firewall"
apt install ufw
ufw default deny incoming && ufw default allow outgoing
ufw allow https
ufw allow 3306
ufw allow 6922
ufw allow http
yes | ufw enable

# Alterando a porta do SSH
echo ""
echo "Alterando a porta do SSH"
sed -i 's/#Port 22/Port 6922/g' /etc/ssh/sshd_config
systemctl restart ssh

echo ""
echo "Instalando o Apache2"
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

echo ""
echo "Instalando o Certificado HTTPS"
apt install -y certbot python3-certbot-apache
certbot --apache --agree-tos --redirect -d www.${DOM_VAL} -m admin@${DOM_VAL}
certbot renew --dry-run
systemctl restart apache2

echo ""
echo "Instalando o PHP"
wget -qO - https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /usr/share/keyrings/sury-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/sury-archive-keyring.gpg] https://packages.sury.org/php/ bookworm main" | tee /etc/apt/sources.list.d/sury-php.list
apt update
apt install -y php8.4-fpm libapache2-mod-fcgid libicu72 
apt install -y php8.4-{bcmath,enchant,ldap,mysql,curl,dba,gd,intl,ldap,mbstring,mcrypt,odbc,opcache,pgsql,sqlite3,pspell,soap,tidy,xml,xmlrpc,xsl,zip} 
a2enmod proxy_fcgi setenvif
a2enconf php8.4-fpm
systemctl enable php8.4-fpm     
systemctl start php8.4-fpm
systemctl restart apache2
echo "<?php phpinfo();?>" | tee /var/www/html/${DOM_VAL}/phpinfo.php

echo ""
echo "Instalando o MariaDB"
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

echo ""
echo "Criando o Banco de Dados"
mariadb <<EOF
CREATE DATABASE maindb;
CREATE USER 'userdb'@'localhost' IDENTIFIED BY '${PASS_VAL}';
GRANT ALL ON maindb.* TO 'userdb'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
EOF

echo ""
echo "Instalando o Adminer"
mkdir -p /var/www/html/${DOM_VAL}/adminer
cd /var/www/html/${DOM_VAL}/adminer
wget https://github.com/vrana/adminer/releases/download/v5.4.1/adminer-5.4.1-mysql-en.php
mv adminer-5.4.1-mysql-en.php adminer.php

# Instalando o Node/NPM
echo ""
echo "Instalando o Node/NPM"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt update
apt install -y nodejs
npm install -g npm@latest







