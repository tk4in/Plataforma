<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# O que você precisa saber para instalar os servidores DNS:
- Nestes servidores vamos usar o <a href="https://www.alpinelinux.org/" target="_blank" rel="noopener noreferrer">Alpine Linux</a> por ser extremamente leve, seguro e focado em performace.<br>
- <b>Ultra Leve:</b> As imagens base do Alpine são minúsculas, cerca de 10 vezes menor do que distribuições como Ubuntu ou Debian. Por ter menos pacotes instalados por padrão, ele possui uma superfície de ataque muito menor.<br>
- <b>Segurança reforçada:</b> Em vez de usar as ferramentas padrão do GNU/Linux (como glibc e coreutils), ele utiliza alternativas otimizadas que garantem vantagens operacionais diretas. Todos os binários são compilados nativamente com recursos de proteção avançados (como Stack Smashing Protection e Position Independent Executables) para dificultar invasões.
- <b>Execução via RAM (Diskless Mode):</b> O sistema pode ser carregado inteiramente na memória RAM, tornando-o ideal para sistemas que exigem alta estabilidade e performance.<br>

# Guia de instalação
- Você vai usar este mesmo guia para fazer os dois servidores de DNS. Basta repetir as instruções usando os parâmetros <b>--dns1</b> ou <b>--dns2</b> como explicado abaixo.  
- Use o pendrive para instalar a ISO [Alpine 3.23.4 kernel 6.18.32-0-lts](https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-standard-3.23.4-x86_64.iso)<br> ou baixe e faça a sua maneira.
- Se precisar aqui tem um <a href="https://www.youtube.com/watch?v=WhOxOof1J1g&t=236s" target="_blank" rel="noopener noreferrer">video</a> ensinando a instalar. Você pode usar todas as opções "default" pois o instalador vai reconfigurar a instalação de acordo com o arquivo <b>config.env</b>.
- Após instalado logar como <b>root</b> e digitar a seguinte sequência de comandos (uma linha por vez):
  
```bash
echo "http://dl-3.alpinelinux.org/alpine/v3.23/main\nhttp://dl-3.alpinelinux.org/alpine/v3.23/community" | tee /etc/apk/repositories
apk update
apk add --upgrade apk-tools
apk upgrade --available --no-interactive
apk add bash
reboot
```

- Após o reboot entre novamente como <b>root</b> e continue a instalação.
- Tenha certeza de que o pendrive está conectado ao PC pois o instalador vai usar o arquivo <b>config.env</b> nele para configurar o servidor.
- Como temos de ter 2 servidores de DNS você tera de informar qual estamos fazendo. Use o parâmetro <b>--dns1</b> para o primeiro e <b>--dns2</b> para o segundo.
- Abaixo vamos usar o <b>WGET</b> para baixar o script do instalador e executa-lo com o parâmetro <b>--dns1</b> para o primeiro servidor.
  
```bash
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/DNS/dns-install.sh && chmod +x dns-install.sh
./dns-install.sh --dns1
```

# Tudo pronto ? Vamos continuar ?
- Deixe os dois servidores ligados pois as próximas etapas vão precisar se comunicar com eles.
- Mude para a pasta [WEB](https://github.com/tk4in/Plataforma/tree/master/WEB) e siga as instruções.
