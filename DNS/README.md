<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# O que você precisa saber para instalar o servidor DNS:
- Neste servidor vamos usar o Alpine Linux por ser extremamente leve, seguro e focado em performace.<br>
<b>Ultra Leve:</b> As imagens base do Alpine são minúsculas, cerca de 10 vezes menor do que distribuições como Ubuntu ou Debian. Por ter menos pacotes instalados por padrão, ele possui uma superfície de ataque muito menor.<br>
<b>Segurança reforçada:</b> Em vez de usar as ferramentas padrão do GNU/Linux (como glibc e coreutils), ele utiliza alternativas otimizadas que garantem vantagens operacionais diretas. Todos os binários são compilados nativamente com recursos de proteção avançados (como Stack Smashing Protection e Position Independent Executables) para dificultar invasões.
 <br><b>Execução via RAM (Diskless Mode):</b> O sistema pode ser carregado inteiramente na memória RAM, tornando-o ideal para sistemas que exigem alta estabilidade e performace.<br>

# Guia de instalação
- Você vai usar este mesmo guia para fazer os dois servidores de DNS. Basta repetir as instruções mudando o parâmetro <b>--dns1</b> ou <b>--dns2</b> como explicado abaixo.  
- Use o pendrive para instalar o [Alpine 3.23.4 kernel 6.18.24-0-lts](https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-standard-3.23.4-x86_64.iso)<br>
- Se precisar aqui tem um <a href="https://www.youtube.com/watch?v=WhOxOof1J1g&t=236s" target="_blank" rel="noopener noreferrer">video</a> ensinando a instalar. Você pode usar todas as opções "default" pois o instalador vai reconfigurar a instalação de acordo como arquivo <b>config.env</b>.
- Após instalado logar como root e digitar a seguinte sequência de comandos (uma linha por vez):
  
```bash
echo -e "http://dl-3.alpinelinux.org/alpine/v3.23/main\nhttp://dl-3.alpinelinux.org/alpine/v3.23/community" | tee /etc/apk/repositories
apk update
apk add --upgrade apk-tools
apk upgrade --available --no-interactive
reboot
```

- Após o reboot entre novamente como root e continua a instalação.
- Tenha certeza de que o pendrive esta conectado ao pc pois o instalador vai usar o arquivo <b>config.env</b> nele para confirar o servidor.
- Como temos de ter 2 servidores de DNS você tera de informar qual estamos fazendo. Use o parâmetro <b>--dns1</b> para o primeiro e <b>--dns2</b> para o segundo.
  
```bash
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/DNS/dns-install.sh && chmod +x dns-install.sh
./dns-install.sh --dns1
```

# Tudo pronto ? Vamos continuar ?
- Deixe as duas maquinas ligadas pois as próximas etapas vão precisar se comunicar com elas.
- Mude para a Pasta [WEB](https://github.com/tk4in/Plataforma/tree/master/WEB) e siga as instruções.
