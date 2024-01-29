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

// Grava estatísticas a acada 60s
setInterval(function() {
			// Publica o STATUS do serviço
			PublishUpdate();
			// Pega data e hora GMT
			let dte = new Date(new Date().getTime()).toISOString().replace(/T/,' ').replace(/\..+/, '');
			// Grava estatísticas
			db.getConnection(function(err,connection){
				if (!err) {
					connection.query('INSERT INTO syslog (datlog,server,version,ipport,devices,msgsin,msgsout,bytsin,bytsout,bytserr) VALUES (?,?,?,?,?,?,?,?,?,?)',[dte, process.title, version, process.env.SrvIP + ':' + process.env.SrvPort, numdev, msgsin, msgsout, bytsin, bytsout, bytserr],function (err, result) {connection.release(); if (err) err => console.error(err);});
				}
				msgsin=0;
				msgsout=0;
				bytsin=0;
				bytsout=0;
				bytserr=0;
			});
},60000);

/****************************************************************************************************/
/* Cria o servidor https que vai servir o conteúdo													*/
/****************************************************************************************************/
const express = require('express')
const http2Express = require('http2-express-bridge')
const http2 = require('http2')
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
  };
  // Verifica se a linguagem e uma da válidas se nao for seta com inglês
  let langs = ["pt-BR", "en-US", "zh-CN"];
  if (!langs.includes(session.lang)) {
    session.lang = "pt-BR";
  }

  // Le a linguagem
  let lang = require("./lang/" + session.lang + "/index");

  nonce = randomBytes(16).toString("hex");
  res.status(200);
  res.set("Content-Type", "text/plain");
  res.send(
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
    res.send("</body></html>");
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