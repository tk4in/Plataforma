<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# Guia de instalação do servidor para maquinas virtuais (VPS)

- E aqui que você vai usar aquela maquina parruda a melhor que você tem.

- Baixar e instalar o Debian 13.4.0 kernel 6.12.85</br>
	https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso

- Após instalado logar como root e digitar a seguinte sequência de comandos (uma linha por vez):
  
```bash
apt update && apt upgrade -y
yes | apt autoremove
apt install sudo -y
sudo su
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/VPS/vps-install.sh && chmod +x vps-install.sh
./vps-install.sh -u <$user> -p <$pass>
```

> [!CAUTION]
>
> Não se esqueça de trocar <$user> e <$pass> para seu usuário e senha respectivamente.
> 

# Vai tomar um café
- Tenha paciência pois a instalação e demorada e complexa, mas não se preocupe e tudo automático.
- Se tudo correr bem (E vai correr pois eu testei milhares de vezes a instalação) o prompt do linux vai aparecer e você ja pode passar para a prôxima etapa.
- Mude para a Pasta WEB e siga as instruções.
