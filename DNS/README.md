<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# Guia de instalação do servidor DNS
- Neste servidor vamos usar o Alpine por ser extremamente leve, seguro e focado em performace.<br>
<b>Ultra Leve:</b> As imagens base do Alpine são minúsculas, cerca de 10 vezes menor do que distribuições como Ubuntu ou Debian. Por ter menos pacotes instalados por padrão, ele possui uma superfície de ataque muito menor.<br>
<b>Segurança reforçada:</b> Em vez de usar as ferramentas padrão do GNU/Linux (como glibc e coreutils), ele utiliza alternativas otimizadas que garantem vantagens operacionais diretas. Todos os binários são compilados nativamente com recursos de proteção avançados (como Stack Smashing Protection e Position Independent Executables) para dificultar invasões.
 <br><b>Execução via RAM (Diskless Mode):</b> O sistema pode ser carregado inteiramente na memória RAM, tornando-o ideal para sistemas que exigem alta estabilidade e performace.
- Baixar e instalar o Alpine 3.23.4 kernel 6.18.24-0-lts</br>
	https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-standard-3.23.4-x86_64.iso

- Após instalado logar como root e digitar a seguinte sequência de comandos (uma linha por vez):
  
```bash
echo -e "http://dl-3.alpinelinux.org/alpine/v3.23/main\nhttp://dl-3.alpinelinux.org/alpine/v3.23/community" | tee /etc/apk/repositories
apk update
apk add --upgrade apk-tools
apk upgrade --available --no-interactive
reboot
```

- Após o reboot entre novamente como root e continua a instalação
  
```bash
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/DNS/dns-install.sh && chmod +x dns-install.sh
./dns-install.sh -u <$user> -p <$pass>
```

> [!CAUTION]
>
> Não se esqueça de trocar <$user> e <$pass> para seu usuário e senha respectivamente.
> 

# Tudo pronto ?
- Mude para a Pasta VPS e siga as instruções.
