<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# Guia de instalação do servidor WEB

- Baixar e instalar o Debian 13.4.0 kernel 6.12.85</br>
	https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso

- Após instalado logar como root e digitar a seguinte sequencia de comandos:
 
```bash
apt update && apt upgrade -y
apt autoremove -y
apt install sudo -y
sudo su
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/WEB/web-install.sh
chmod +x web-install.sh
./web-install.sh -u kvmuser -p <$pass>
```
