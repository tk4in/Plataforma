<h1><img alt="Tk4in logo" src="https://raw.githubusercontent.com/tk4in/Plataforma/refs/heads/master/media/tk4in.png" height="142"/></h1>

# Este projeto consiste de uma plataforma web para gerenciamento de VPS`s  

> [!IMPORTANT]
> Este projeto esta sempre em mudança. [Por favor reporte erros ou faltas aqui](https://github.com/tk4in/Plataforma.wiki-site/issues/new)
>
> Vamos tentar resolver o mais rápido possível.

## Hardware necessário
- Um pendrive de 16GB (para instalação das ISO`s linux)
- Uma Routerboard MikroTik (Testado em uma [RB3011-UiAS-RM](https://mikrotik.com/product/RB3011UiAS-RM) e na [RB1100-AHx4](https://mikrotik.com/product/rb1100ahx4))
- Um PC para o servidor DNS (pode ser uma mais simples)
- Um PC para o servidor das VM's (Separe a melhor maquina que você tiver)
- Um PC para o servidor web e banco de dados.
  
## Sequência de instalação
- Comece criando um pendrive bootável com as ISO`s do linux que vamos usar. ([Instruções logo abaixo](#criando-um-pendrive-bootavel))
- Reuna as informações para a Plataforma e crie o arquivo <b>config.env.</b> (dominio, IP, gateway, etc.. Tabela logo abaixo)
- Configure a Routerboard (instruções na pasta [RTB](https://github.com/tk4in/Plataforma/tree/master/RTB))
- Instale o servidor de DNS (instruções na pasta [DNS](https://github.com/tk4in/Plataforma/tree/master/DNS))
- Instale o servidor para as VM`s (instruções na pasta [VPS](https://github.com/tk4in/Plataforma/tree/master/VPS))
- Instale o servidor WEB (instruções na pasta [WEB](https://github.com/tk4in/Plataforma/tree/master/WEB))

## Criando um pendrive bootável
- Use o [VENTOY](https://www.ventoy.net/) para cria o pendrive bootável, ele e simples e facil de usar. [Download](https://www.ventoy.net/en/download.html)
- Após criar o pendrive faça download das distribuiçoes linux (tabela abaixo) e copie para o pendrive.
    
## Estas são as distribuições que vamos usar para a VPS.
| Distribuição | Kernel | link | Tamanho (KB)|
|:---|:---|:---|---:|
| Almalinux 10.1 | 6.12.0 | https://repo.almalinux.org/almalinux/10/isos/x86_64/AlmaLinux-10.1-x86_64-minimal.iso | 1.499.840|
| Alpinelinux 3.23.4 | 6.18.24-0-lts | https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-standard-3.23.4-x86_64.iso | 355.328|
| Debian 13.0.4 | 6.12.85 | https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso | 772.096|
| Ubuntu 22.04.5 | 6.8 | https://releases.ubuntu.com/22.04.5/ubuntu-22.04.5-live-server-amd64.iso | 2.086.842|
| Ubuntu 24.04.4 LTS| 6.8.0-111-generic | https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso | 3.325.654|
| Ubuntu 26.04 LTS | 7.0.3 | https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso | 2.850.194|

## Criando o arquivo config.env
- Você pode baixar o arquivo exemplo [aqui](https://github.com/tk4in/Plataforma/tree/master/config.env) e preencher os campos.<br>
- Após preencher corretamente copie o arquivo para o pendrive. Os instaladores vão usa-lo para as configurações. 

| Parâmetro | Exemplo | Descrição |
|:---|:---|:---|
|$DOM_VAL| meudominio.com.br | Nome de dominio do site |
|$USER_VAL| useradm | Nome do usuário |
|$PASS_VAL| P4$$w0rd123 | Senha para o usuário |
|$IP_VAL| P4$$w0rd123 | Senha para o usuário |
|$GW_VAL| P4$$w0rd123 | Senha para o usuário |

## Vamos ao trabalho
- A primeira coisa que vamos fazer e configurar a Routerboard
- [Configurando a routerboard.](https://github.com/tk4in/Plataforma/tree/master/RTB)
