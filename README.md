<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# Este projeto consiste de uma plataforma web para gerenciamento de VPS`s  

> [!IMPORTANT]
> Este projeto ainda está em desenvolvimernto. [Por favor reporte erros ou faltas aqui](https://github.com/tk4in/Plataforma.wiki-site/issues/new)
>
> Vamos tentar resolver o mais rápido possível.

## Hardware necessário
- Um pendrive de 16GB (para instalação das ISO`s linux)
- Um notebook para configurar a Routerboard (tambem serve um PC)
- Uma Routerboard MikroTik (Testado em uma [RB3011-UiAS-RM](https://mikrotik.com/product/RB3011UiAS-RM) e na [RB1100-AHx4](https://mikrotik.com/product/rb1100ahx4))
- Dois PC`s para os servidores DNS. (Podem ser maquinas mais simples)
- Um PC para o servidor web e banco de dados. (Precisa ser uma maquina boa tambem)
- Um PC para o servidor das VM's. (Separe a melhor maquina que você tiver)

## Esquema de ligação
- So pra deixar claro o segundo link não foi implementado mas deixa a porta vazia vamos fazer em breve.
- Neste exemplo so tem um servidor VPS, mas nada impede de você colocar uma segunda, terceira ou quarta maquina.
<img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/connect.png" height="480"/>

## Sequência de instalação
- Comece criando um pendrive bootável com as ISO`s do linux que vamos usar. ([Instruções logo abaixo](#criando-um-pendrive-bootável))
- Reuna as informações para criar o arquivo <b>config.env.</b> (dominio, IP, gateway, etc.. [Tabela logo abaixo](#criando-o-arquivo-configenv))
- Entre no registro do dominio que será usado e aponte para o seu servidor DNS. ([Instruções logo abaixo](#apontando-seu-dominio-para-o-seu-servidor-de-dns))
- Configure a Routerboard (instruções na pasta [RTB](https://github.com/tk4in/Plataforma/tree/master/RTB))
- Instale os servidores de DNS (instruções na pasta [DNS](https://github.com/tk4in/Plataforma/tree/master/DNS))
- Instale o servidor WEB (instruções na pasta [WEB](https://github.com/tk4in/Plataforma/tree/master/WEB))
- Instale o servidor para as VM`s (instruções na pasta [VPS](https://github.com/tk4in/Plataforma/tree/master/VPS))

## Criando um pendrive bootável
- Use o [VENTOY](https://www.ventoy.net/) para cria o pendrive bootável, ele e simples e fácil de usar. [Download](https://www.ventoy.net/en/download.html)
- Após criar o pendrive faça download das distribuiçoes linux (tabela abaixo) e copie para o pendrive.
    
| Distribuição | Kernel | link | Tamanho (KB)|
|:---|:---|:---|---:|
| Almalinux 10.1 | 6.12.0 | https://repo.almalinux.org/almalinux/10/isos/x86_64/AlmaLinux-10.1-x86_64-minimal.iso | 1.499.840|
| Alpinelinux 3.23.4 | 6.18.24-0-lts | https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-standard-3.23.4-x86_64.iso | 355.328|
| Debian 13.0.4 | 6.12.85 | https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso | 772.096|
| Ubuntu 22.04.5 | 6.8 | https://releases.ubuntu.com/22.04.5/ubuntu-22.04.5-live-server-amd64.iso | 2.086.842|
| Ubuntu 24.04.4 LTS| 6.8.0-111-generic | https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso | 3.325.654|
| Ubuntu 26.04 LTS | 7.0.3 | https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso | 2.850.194|

## Criando o arquivo config.env
- Você pode baixar o arquivo exemplo [aqui](https://github.com/tk4in/Plataforma/tree/master/config.env) e preencher os campos conforme tabela abaixo.<br>
- Após preencher corretamente copie o arquivo para o pendrive. Os instaladores vão usá-lo para as configurações. 

| Parâmetro | Exemplo | Descrição |
|:---|:---|:---|
|$DOM_VAL| meudominio.com.br | Nome de dominio do site |
|$USER_VAL| useradm | Nome do usuário |
|$PASS_VAL| P4$$w0rd123 | Senha para o usuário |
|$IP_VAL| 200.xxx.xxx.210/29 | IP e mascara fornecido pela operadora |
|$GW_VAL| 200.xxx.xxx.209 | Gateway |
|$DNS1_NAM| dns1 | Nome do primeiro servidor de DNS. (dns1.meudominio.com.br) |
|$DNS2_NAM| dns2 | Nome do segundo servidor de DNS. (dns2.meudominio.com.br) |
|$WEB1_NAM| websrv1 | Nome do servidor WEB "websrv1.meudominio.com.br" |
|$VPS1_NAM| vpssrv1 | Nome do primeiro servidor VPS "vpssrv1.meudominio.com.br" |
|$SSH_PORT| 2222 | Porta para o SSH |

## Apontando seu dominio para o seu servidor de DNS
- Esta operação e simples mas varia depedendo de onde você registrou seu dominio
- Se você registrou na GoDaddy aqui esta um video ensinado [GoDaddy](https://www.youtube.com/watch?v=ogyzNSYcazI)
- Se foi na Hostinger aqui estas um link ensinando [Hostinger](https://www.hostinger.com/br/support/1696789-como-alterar-os-nameservers-na-hostinger/)
- Se for qualquer outro pergunte ao Google, o importante e fazer e não se preocupe e simples
    
## Vamos ao trabalho
- Após realizar as etapas acima estamos prontos para começar a configuração
- [Configurando a routerboard.](https://github.com/tk4in/Plataforma/tree/master/RTB)
