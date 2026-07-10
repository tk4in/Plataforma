<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# O que você precisa saber para instalar os servidores DNS:
- Nestes servidores vamos usar o <a href="https://www.alpinelinux.org/" target="_blank" rel="noopener noreferrer">Alpine Linux</a> por ser extremamente leve, seguro e focado em performance.<br>
- <b>Ultra Leve:</b> As imagens base do Alpine são minúsculas, cerca de 10 vezes menor do que distribuições como Ubuntu e metade do Debian. Por ter menos pacotes instalados por padrão, ele possui uma superfície de ataque muito menor.<br>
- <b>Segurança reforçada:</b> Em vez de usar as ferramentas padrão do GNU/Linux (como glibc e coreutils), ele utiliza alternativas otimizadas que garantem vantagens operacionais diretas. Todos os binários são compilados nativamente com recursos de proteção avançados (como Stack Smashing Protection e Position Independent Executables) para dificultar invasões.
- <b>Execução via RAM (Diskless Mode):</b> O sistema pode ser carregado inteiramente na memória RAM, tornando-o ideal para sistemas que exigem alta estabilidade e performance.<br>

# Guia de instalação
- Por motivos de redundância e segurança vamos fazer dois servidores de DNS.
- Você vai usar este mesmo guia para fazer os dois servidores. Basta repetir as instruções usando os parâmetros <b>--dns1</b> ou <b>--dns2</b> como explicado abaixo.  
- Use o pendrive para instalar a ISO do [Alpine 3.24 kernel 6.18.38-0-lts](https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-standard-3.24.1-x86_64.iso).
- Se precisar aqui tem um <a href="https://www.youtube.com/watch?v=WhOxOof1J1g&t=236s" target="_blank" rel="noopener noreferrer">video</a> ensinando a instalar. Você pode usar todas as opções "default" pois o instalador vai reconfigurar a instalação de acordo com o arquivo <b>config.env</b>.
- Após instalado logar como <b>root</b> e digitar a sequência de comandos abaixo (uma linha por vez) para atualizar os packs mais recentes do Alpine:
  
```bash
sed -i "s/#http/http/g" /etc/apk/repositories
apk update
apk add --upgrade apk-tools
apk upgrade --available --no-interactive
apk add bash
reboot
```

- Após o reboot entre novamente como <b>root</b>.
- Tenha certeza de que o pendrive está conectado ao PC pois o instalador vai usar o arquivo <b>config.env</b> que colocamos nele para configurar o servidor.
- Abaixo vamos usar o <b>WGET</b> para baixar o script do instalador e executa-lo com o parâmetro <b>--dns1</b> para o primeiro servidor.
- Como temos de ter 2 servidores de DNS você tera de informar qual estamos fazendo. Use o parâmetro <b>--dns1</b> para o primeiro e <b>--dns2</b> para o segundo.
  
```bash
wget https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/DNS/dns-install.sh && chmod +x dns-install.sh
./dns-install.sh --dns1
```

# Tudo pronto ? Vamos continuar ?
- Deixe os dois servidores ligados pois as próximas etapas vão precisar se comunicar com eles.
- Mude para a pasta [WEB](https://github.com/tk4in/Plataforma/tree/master/WEB) e siga as instruções.
