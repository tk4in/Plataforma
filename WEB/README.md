<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# O que você precisa saber para instalar o servidor WEB:
- Neste servidor vamos usar o <a href="https://www.debian.org/download" target="_blank" rel="noopener noreferrer">Debian Linux</a> por ser um dos mais leves e conhecidos.<br>

# Guia de instalação do servidor WEB
- Use o pendrive para instalar a ISO do [Debian 13.4.0 kernel 6.12.85](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso).
- Após instalado logar como <b>root</b> e digitar a sequência de comandos abaixo (uma linha por vez) para atualizar os packs mais recentes do Debian:
 
```bash
apt update && apt upgrade -y
yes | apt autoremove
apt install sudo -y
sudo su
reboot
```

- Após o reboot entre novamente como <b>root</b>.
- Tenha certeza de que o pendrive está conectado ao PC pois o instalador vai usar o arquivo <b>config.env</b> que colocamos nele para configurar o servidor.
- Abaixo vamos usar o <b>WGET</b> para baixar o script do instalador e executa-lo.

```bash
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/WEB/web-install.sh && chmod +x web-install.sh
./web-install.sh
```

# Tudo pronto ? Vamos continuar ?
- Mude para a pasta [VPS](https://github.com/tk4in/Plataforma/tree/master/VPS) e siga as instruções.
