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
apt install -y nano curl wget git sed subversion libtool

echo -e "\n\e[32mInstalando o Firewall\e[0m"
apt install ufw
ufw default deny incoming && ufw default allow outgoing
ufw allow 53/tcp
ufw allow 53/udp
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

echo -e "\n\e[32mInstalando o Bind9\e[0m"
apt install -y bind9 bind9utils bind9-doc dnsutils

echo -e "\n\e[32mInstalando o End Point pra o DNS\e[0m"
mkdir -p /home/${USER_VAL}/epdns
wget -r -np -nH -O /var/home/${DOM_VAL}/epdns https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/DNS/epdns
echo "[Unit]
Description=End Point para receber as atualizações do DNS
After=network.target

[Service]
Type=simple
User=${USER_VAL}
WorkingDirectory=/home/${USER_VAL}/epdns
ExecStart=/usr/bin/node epdns.js
Restart=always
# Configura variáveis de ambiente se necessário
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target" | tee /etc/systemd/system/epdns.service
sudo systemctl daemon-reload
sudo systemctl enable epdns.service
sudo systemctl start epdns.service
