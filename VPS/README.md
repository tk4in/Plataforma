<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# Guia de instalação do servidor para maquinas virtuais (VPS)


Instalando os servidores de VM
- Baixar e instalar o Debian 13.4.0 kernel 6.12.85
	https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso

- Apos instalado logar como root e digitar a seguinte sequencia de comandos:
  
> [!CAUTION]
>
> Não se esqueca de trocar <$pass> por uma senha para o usuario kvmuser
> 

```bash
apt update && apt upgrade && apt autoremove -y
apt install sudo -y
sudo su
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/vps-install.sh
chmod +x vps-install.sh
./vps-install.sh -u kvmuser -p <$pass>
```
