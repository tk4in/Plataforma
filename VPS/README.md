Instalando os servidores de VM
- Baixar e instalar o Debian 13.4.0 kernel 6.12.85
	https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso

- Apos instalado logar como root e digitar a seguinte sequencia de comandos:

```bash
apt update && apt upgrade -y
apt autoremove -y
apt install sudo -y
sudo su
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VM/vm-install.sh
chmod +x vm-install.sh
./vm-install.sh -u kvmuser -p <$pass>
```
