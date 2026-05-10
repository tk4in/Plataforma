> [!CAUTION]
> NOTICE OF BREAKING CHANGE.
>
> As of 7.0.0, multiple breaking changes were introduced into the library.
>
> Please check out https://whiskey.so/migrate-latest for more information.


# Guia de instalação do servidor para maquinas virtuais (VPS)

Instalando os servidores de VM
- Baixar e instalar o Debian 13.4.0 kernel 6.12.85
	https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso

- Apos instalado logar como root e digitar a seguinte sequencia de comandos:

# Usage & Guide

> [!IMPORTANT]
> The new guide is a work in progress. Expect missing pages/content. [Report missing or incorrect content.](https://github.com/WhiskeySockets/baileys.wiki-site/issues/new)
>
> **You can still access the old guide here:** [README.md](https://github.com/WhiskeySockets/Baileys/tree/master/README.md), or the [NPM homepage](https://npmjs.com/package/baileys).




```bash
apt update && apt upgrade && apt autoremove -y
apt install sudo -y
sudo su
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/vps-install.sh
chmod +x vps-install.sh
./vps-install.sh -u kvmuser -p <$pass>
```
