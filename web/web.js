/****************************************************************************************************/
/* WEB		                                                                                        */
/* Para executar use: node web.js &        		                                                    */
/****************************************************************************************************/
process.title = 'web';
const version = '2.0.0';

const { GetDate, GetUSID } = require('../utils/utils.js');

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
		pub.publish('san:server_update', '{"app":"' + process.env.AppID+'","version":"' + process.env.CoreVersion+'","addr":"https://'+process.env.WEBAddr+'/","uptime":"'+Math.floor(uptime/60000)+'"}');
	});
}

// Publica o STATUS assim que se conectar no HUB
hub.on('connect', function () { PublishUpdate(); GetDate().then(dte =>{ console.log('\u001b[36m'+dte+': \u001b[32mHUB conectado.\u001b[0;0m');
																		console.log('\u001b[36m'+dte+': \u001b[32mAguardando clientes...\u001b[0;0m');}); });

// Se inscreve nos canais para receber comunicações
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

// Inicializa variáveis globais																	
var starttime=0,numdev=0,msgsin=0,msgsout=0,bytsin=0,bytsout=0,bytserr=0;

// Grava estatísticas a cada 60s
setInterval(function() {
  // Publica o STATUS do serviço
  PublishUpdate();
  // Pega data e hora GMT
  let dte = new Date(new Date().getTime()).toISOString().replace(/T/, " ").replace(/\..+/, "");
  // Atualiza banco de dados
  db.getConnection(function (err, connection) {
    if (!err) {
 	  connection.query("INSERT INTO syslog (datlog,server,version,ipport,devices,msgsin,msgsout,bytsin,bytsout,bytserr) VALUES (?,?,?,?,?,?,?,?,?,?)",
	    [dte, process.env.AppID, process.env.CoreVersion, 'https://'+process.env.WEBAddr+'/', numdev, msgsin, msgsout, bytsin, bytsout, bytserr],
	    function (err, result) {
		  connection.release();
		  if (err) (err) => console.error(err);
	    }
	  );
    }
    msgsin = 0;
    msgsout = 0;
    bytsin = 0;
    bytsout = 0;
    bytserr = 0;
  });
}, 60000);

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

server.listen(443, () => {
	GetDate().then(dte =>{console.log('\u001b[36m'+dte+': \u001b[32mHTTPS Server rodando na porta 443'+'.\u001b[0;0m');});
});

const cookie = require("cookie");
app.use(function (req, res, next) {
  var cookies = cookie.parse(req.headers.cookie || "");

  
  next();
});

/****************************************************************************************************/
/* Rotas											                                              	*/
/****************************************************************************************************/
const root = require("./root");
app.use("/", root);

const main = require("./main");
app.use("/", main);

app.get("/favicon.ico", function (req, res) {
	res.set("Content-Type", "image/x-icon");
	res.status(200).end();
});

/****************************************************************************************************/
/* 	Mostra os parâmetros no Log e aguarda conexões							                        */
/****************************************************************************************************/
const OS = require('node:os');

GetDate().then(dte => {
	// Guarda date e hora de início do servidor
	starttime = Date.parse(dte);
	// Mostra parâmetros no LOG
	console.log('\u001b[36m'+dte+': \u001b[37m================================');
	console.log('\u001b[36m'+dte+': \u001b[37mAPP : ' + process.env.AppID + ' ('+process.env.CoreVersion+')');
	console.log('\u001b[36m'+dte+': \u001b[37mDomínio : https://' + process.env.WEBAddr);
	console.log('\u001b[36m'+dte+': \u001b[37mCPUs: '+ OS.cpus().length);
	console.log('\u001b[36m'+dte+': \u001b[37m================================');});