/****************************************************************************************************/
/* WEB		                                                                                        */
/* Para executar use: node web.js &        		                                                    */
/****************************************************************************************************/
process.title = 'web';
const version = 'v2.0.0';

const { GetDate, GetUSID } = require('../utils/utils.js');
const { randomBytes } = require("node:crypto");

/****************************************************************************************************/
/* Inicializa variáveis globais																		*/
/****************************************************************************************************/
var starttime=0,numdev=0,msgsin=0,msgsout=0,bytsin=0,bytsout=0,bytserr=0;

/****************************************************************************************************/
/* Le as variáveis de ambiente																		*/
/****************************************************************************************************/
require('dotenv').config({ path: '../.env' });

/****************************************************************************************************/
/* Cria e abre uma conexão Redis	 																*/
/****************************************************************************************************/
const Redis = require('ioredis');
const hub = new Redis({host:process.env.RD_host, port:process.env.RD_port, password:process.env.RD_pass});
const pub = new Redis({host:process.env.RD_host, port:process.env.RD_port, password:process.env.RD_pass});

// Publica o STATUS do serviço
async function PublishUpdate() {
	GetDate().then(dte => {
		let uptime = Date.parse(dte) - starttime;
		pub.publish('san:server_update','{"name":"'+process.title+'","version":"'+version+'","ipport":"'+process.env.WWWIP+':'+process.env.WWWPort+'","uptime":"'+Math.floor(uptime/60000)+'"}');
	});
}

// Publica o STATUS assim que se conectar no HUB
hub.on('connect', function () { PublishUpdate(); GetDate().then(dte =>{ console.log('\u001b[36m'+dte+': \u001b[32mHUB conectado.\u001b[0;0m');
																		console.log('\u001b[36m'+dte+': \u001b[32mAguardando clientes...\u001b[0;0m');}); });

// Se increve nos canais para receber comunicações
hub.subscribe("san:server_update","san:monitor_update", (err, count) => {
  if (err) {
	console.log('\u001b[36m'+dte+': \u001b[31mFalha na inscrição: '+ err.message +'\u001b[0m');
  } 
});

// Aguarda messagens dos canais
hub.on("message", (channel, message) => {
  switch (channel) {
	case 'san:server_update' :
		break;

	case 'san:monitor_update' :
		io.emit("dev_monitor",message);
		break;
  }

});

/****************************************************************************************************/
/* Cria e abre uma conexão MySQL																	*/
/****************************************************************************************************/
const mysql = require('mysql2');
const db = mysql.createPool({host:process.env.DB_host, database:process.env.DB_name, user:process.env.DB_user, password:process.env.DB_pass, connectionLimit:10});

// Grava estatísticas a cada 60s
setInterval(function() {
			// Publica o STATUS do serviço
			PublishUpdate();
},60000);

/****************************************************************************************************/
/* Cria o servidor https que vai servir o conteúdo													*/
/****************************************************************************************************/
const express = require('express')
const http2Express = require('http2-express-bridge')
const http2 = require('node:http2')
const { readFileSync } = require('node:fs')
const app = http2Express(express)

// Cria o servidor
const server = http2.createSecureServer({
  key: readFileSync('/etc/letsencrypt/live/tk4.in/privkey.pem', 'utf8'),
  cert: readFileSync('/etc/letsencrypt/live/tk4.in/cert.pem', 'utf8'),
  ca: readFileSync('/etc/letsencrypt/live/tk4.in/fullchain.pem', 'utf8'),
  allowHTTP1 : true
}, app);

server.listen(process.env.WWWPort, () => {
	GetDate().then(dte =>{console.log('\u001b[36m'+dte+': \u001b[32mHTTPS Server rodando na porta '+process.env.WWWPort+'.\u001b[0;0m');});
});

/****************************************************************************************************/
/* Rotas																							*/
/****************************************************************************************************/
app.get("/", function (req, res) {
  // Inicializa a sessao
  let session = {
    cookies: {},
    gets: {},
    remoteAddress: {},
    err: 0,
    name: "",
    USID: "teste"
  };
  // Verifica se a linguagem e uma da válidas se nao for seta com inglês
  let langs = ["pt-BR", "en-US", "zh-CN"];
  if (!langs.includes(session.lang)) {
    session.lang = "pt-BR";
  }

  app.set("x-powered-by", false);
  
  nonce = randomBytes(16).toString("hex");
  res.writeHead(200, {
    "access-control-allow-methods": "GET,POST",
    "access-control-allow-origin": "'" + process.env.WWWBase + "'",
    "cache-control": "no-cache",
    "content-security-policy":
      "default-src 'self'; base-uri 'self'; script-src 'report-sample' 'nonce-" +
      nonce +
      "' cdn.jsdelivr.net/npm/ " +
      process.env.CDNBase +
      "; style-src 'self' 'report-sample' cdn.jsdelivr.net/npm/ " +
      process.env.CDNBase +
      "; object-src 'none'; frame-src 'self'; frame-ancestors 'none'; img-src 'self' " +
      process.env.CDNBase +
      "; font-src cdnjs.cloudflare.com/ajax/libs/font-awesome/; connect-src 'self' *.mapbox.com/; form-action 'self'; media-src 'self'; worker-src 'self'",
    "content-type": "text/html; charset=UTF-8",
    date: new Date().toUTCString(),
    "permissions-policy": 'geolocation=(self "' + process.env.WWWBase + '")',
    "referrer-policy": "no-referrer-when-downgrade",
    "set-cookie":
      "tk_v=" +
      session.USID +
      "; Domain=" +
      process.env.CKEBase +
      "; Path=/; Secure; HttpOnly",
    "strict-transport-security": "max-age=31536000; includeSubDomains; preload",
    vary: "Accept-Encoding",
    "x-content-type-options": "nosniff",
    "x-frame-options": "DENY",
    "x-permitted-cross-domain-policies": "none",
    "x-xss-protection": "1; mode=block",
  });
  // Le a linguagem
  let lang = require("./lang/" + session.lang + "/index");
  // Html
  res.write(
    "<!DOCTYPE html><html itemscope itemtype='http://schema.org/WebSite'; lang=" +
      session.lang +
      "><head><meta name='viewport' content='width=device-width, initial-scale=1'><meta charset=utf-8><title itemprop=name>" +
      lang._TITLE +
      "</title><link rel=dns-prefetch href=" +
      process.env.CDNBase +
      "><link rel=canonical href=" +
      process.env.WWWBase +
      " itemprop=url><link rel=icon href='" +
      process.env.CDNBase +
      "img/logo.png' itemprop=image><link rel=preload href='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.2/webfonts/fa-regular-400.woff2' as=font type='font/woff2' crossorigin=anonymous><link rel=preload href='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.2/webfonts/fa-solid-900.woff2' as=font type='font/woff2' crossorigin=anonymous><meta name=description content='" +
      lang._DESCRIPTION +
      "' itemprop=description><meta name=keywords content='" +
      lang._KEYWORDS +
      "'><meta name=apple-mobile-web-app-capable content=yes><meta name=apple-mobile-web-app-status-bar-style content=black-translucent><link href='https://cdn.jsdelivr.net/npm/bootstrap@5.3.1/dist/css/bootstrap.min.css' rel=stylesheet integrity='sha384-4bw+/aepP/YC94hEpVNVgiZdgIC5+VKNBQNGCHeKRQN+PtmoHDEXuppvnDJzQIu9' crossorigin=anonymous><link href='" +
      process.env.CDNBase +
      "css/style.css' rel=stylesheet crossorigin=anonymous></head><body>"
  );
  // Block
  res.write(
    "<div class=loader-wrap id=loader-wrap><div class=blocks><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div></div></div>"
  );
  // Body
  res.write(
    "<section id=content class=login-content><div id=login-box class='login-box" +
      (session.err === 4 ? " flipped" : "") +
      "'><form class=login-form action=login method=post name=logform'><h3 class=login-head><i class='fa fa-fw fa-lg fa-user'></i>" +
      lang._LOGIN +
      "</h3><div class=qr-form id=qrid><div class=form-group><label for=login>" +
      lang._NAME +
      "</label><input class=form-control name=login id=login value='" +
      session.name +
      "'"
  );

  if (0 !== session.err) {
    res.write(
      " data-bs-toggle='popover' data-bs-placement='top' data-bs-trigger='manual' data-bs-title='"
    );
    switch (session.err) {
      case 1: {
        res.write(lang._LOGERR);
        break;
      }
      case 2: {
        res.write(lang._EMAILAUT);
        break;
      }
      case 4: {
        res.write(lang._EMAILERR);
        break;
      }
      case 8: {
        res.write(lang._DBERR);
        break;
      }
    }
    res.write("'");
  }
  res.write(
    " autocomplete=off></div><div class=form-group><label for=pass>" +
      lang._PASS +
      "</label><input class=form-control name=pass id=pass type=password></div><div class=form-group><div class=utility><div class=animated-checkbox><label><input type=checkbox name=rm><span class=label-text>" +
      lang._STAY +
      "</span></label></div><p class='semibold-text mb-2'><a href='#' name=flip>" +
      lang._FORGOT +
      "<i class='fa fa-fw fa-angle-right'></i></a></p></div></div><div class='form-group btn-container'><button type=submit class='btn btn-primary btn-block snd' name=log id=log><i class='fa fa-fw fa-lg fa-sign-in-alt'></i>" +
      lang._SEND +
      "</button></div></div></form><form class=forget-form action=register method=post><h3 class=login-head><i class='fa fa-fw fa-lg fa-lock'></i>" +
      lang._FORGOTPASS +
      "</h3><div class=form-group><label for=email>" +
      lang._EMAIL +
      "</label><input class=form-control name=email id=email value='" +
      session.name +
      "' autocomplete=off></div><div class='form-group mt-3'><p class='semibold-text mb-0'><a href='#' name=flip><i class='fa fa-fw fa-angle-left'></i>" +
      lang._BACK +
      "</a></p></div><div class='form-group btn-container'><button type=button class='btn btn-primary btn-block snd' name=fgt><i class='fa fa-fw fa-lg fa-unlock'></i>" +
      lang._SEND2 +
      "</button></div></form><h2 class=cipher><i class='fa fa-fw fa-lock'></i>" +
      lang._CIPHER +
      "</h2></div></section>"
  );

  // Scripts
  res.write(
    "<script async src='https://cdn.jsdelivr.net/npm/bootstrap@5.3.1/dist/js/bootstrap.bundle.min.js' integrity='sha384-HwwvtgBNo3bZJJLYd8oVXjrBZt8cqVSpeBNS5n7C8IVInixGAoxmnlMuBnhbgrkm' crossorigin=anonymous></script><script nonce=" +
      nonce +
      ">const es=document.getElementsByName('flip');Array.from(es).forEach(function (e){e.addEventListener('click', function(){document.getElementById('login-box').classList.toggle('flipped');});});document.getElementById('log').addEventListener('click', function(){document.getElementById('content').classList.add('blured');document.getElementById('loader-wrap').style.display='block';});"
  );
  res.end("</script></body></html>");
  
});

app.get("/favicon.ico", function (req, res) {
	res.set("Content-Type", "image/x-icon");
	res.status(200).end();
});

/****************************************************************************************************/
/* 	Mostra os parâmetros no Log e aguarda conexões													*/
/****************************************************************************************************/
const OS = require('node:os');

GetDate().then(dte => {
	// Guarda date e hora de início do servidor
	starttime = Date.parse(dte);
	// Mostra parâmetros no LOG
	console.log('\u001b[36m'+dte+': \u001b[37m================================');
	console.log('\u001b[36m'+dte+': \u001b[37mAPP : ' + process.title + ' ('+version+')');
	console.log('\u001b[36m'+dte+': \u001b[37mIP/Port : ' + process.env.WWWIP + ':' + process.env.WWWPort);
	console.log('\u001b[36m'+dte+': \u001b[37mCPUs: '+ OS.cpus().length);
	console.log('\u001b[36m'+dte+': \u001b[37m================================');});

/*
	https://github.com/shubham-thorat/http2-server/blob/main/src/app.js
	https://github.com/georgewitteman/http2/blob/main/index.js
	https://github.com/giesberge/krakend_http2_stream_test/blob/master/server/server.js
	https://github.com/sohamkamani/node-http2-example/blob/main/server.jshttps://github.com/passport90/servant/blob/main/main.js
*/