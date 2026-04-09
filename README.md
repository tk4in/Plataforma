
sudo su
apt update -y && apt upgrade -y
systemctl reboot
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/pre-install.sh
chmod +x pre-install.sh
./pre-install.sh -d max7.in -u admin -p P@$$word10

# tk4in
-Para renovar o certifica letsencript

sudo systemctl stop httpd

sudo certbot certonly --standalone
