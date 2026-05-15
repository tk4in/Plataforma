<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# Guia de instalação do servidor DNS

- Baixar e instalar o Alpine 3.23.4 kernel 6.18.22-0-lts</br>
	https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-standard-3.23.4-x86_64.iso

- Após instalado logar como root e digitar a seguinte sequência de comandos (uma linha por vez):
  
```bash
apk update && apk upgrade --no-interactive
lbu commit
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/DNS/dns-install.sh && chmod +x dns-install.sh
./dns-install.sh -u <$user> -p <$pass>
```

> [!CAUTION]
>
> Não se esqueça de trocar <$user> e <$pass> para seu usuário e senha respectivamente.
> 

# Tudo pronto ?
- Mude para a Pasta VPS e siga as instruções.
