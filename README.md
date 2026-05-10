<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>
# Este projeto consiste de uma plataforma web para gerenciamento de VPS`s  

> [!IMPORTANT]
> Este projeto esta sempre em mudança. [Por favor reporte erros ou faltas aqui](https://github.com/tk4in/Plataforma.wiki-site/issues/new)
> Vamos tentar resolver o mais rapido possivel.

# Quais distribuições vamos usar para as VM's
- Almalinux 10.1 - Kernel 
https://repo.almalinux.org/almalinux/10/isos/x86_64/AlmaLinux-10.1-x86_64-minimal.iso
- Alpinelinux 3.23.4 - Kernel
https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-standard-3.23.4-x86_64.iso
- Debian 13.0.4 - Kernel 6.12.85:
https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso
- Ubuntu 22.04.5 Kernel
https://releases.ubuntu.com/22.04.5/ubuntu-22.04.5-live-server-amd64.iso
- Ubuntu 24.04.4 - Kernel
https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso
-Ubuntu 26.04 LTS - Kernel 7.0.3
https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso

# Guia de instalação do servidor para maquinas virtuais (VPS)


Instalando os servidores de VM
- Baixar e instalar o Debian 13.4.0 kernel 6.12.85
	https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso

- Apos instalado logar como root e digitar a seguinte sequencia de comandos:


```bash
apt update && apt upgrade && apt autoremove -y
apt install sudo -y
sudo su
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/vps-install.sh
chmod +x vps-install.sh
./vps-install.sh -u kvmuser -p <$pass>
```
