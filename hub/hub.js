/*******************************************************/
/* HUB	                                               */
/* Para executar use: node hub.js &                 */
/*******************************************************/
process.title = 'hub';
const version = 'v1.0.0';

const { GetDate } = require('../utils/utils.js');

/****************************************************************************************************/
/* Le as variáveis de ambiente																		*/
/****************************************************************************************************/
require('dotenv').config({ path: '../.env' });

/****************************************************************************************************/
/* Gera as chaves publica e privada para encriptar													*/
/****************************************************************************************************/
const { generateKeyPairSync, createSign, createVerify } = require('node:crypto');
const { publicKey, privateKey } = generateKeyPairSync('rsa',
    {
        modulusLength: 2048,
        publicKeyEncoding: {type: 'pkcs1',format: 'pem'},
        privateKeyEncoding: {type: 'pkcs1', format: 'pem'}
    });

/****************************************************************************************************/
/* Create and open express connection 																*/
/****************************************************************************************************/
const app = require('express');
const http = require('http').createServer(app);
http.listen(process.env.HUBPort || 50900);

/****************************************************************************************************/
/* Socket.io      																					*/
/****************************************************************************************************/
const io = require('socket.io')(http, {
	cors: {
	  origin: '*',
	}
  });

io.on('connection', (socket) =>{
	// Envia nome do app versao e a chave publica para troca de messagens
	socket.emit('message', `{"msgid":"HELLO","content":{"app":"${process.title}","version":"${version}","pubkey":"${publicKey}"}}`);
	// Inicializa a sessão
    socket.on('session', (data)=>{
	    //socket.emit('begin_update', '{"name":"'+process.title+'","version":"'+Version+'"}');
		GNSSInfo(socket, -23.513346, -46.631134);
    })
	// Trata as memssagens
    socket.on('message', (msg)=>{
		let jmsg = JSON.parse(msg);
		switch (jmsg.msgid) {
			case 'START': // Inicializa a sessão




				break;
		}
        //socket.broadcast.emit('message', msg);
    })
});

async function SendMsg(socket, msgid, content) {
	signer = createSign("RSA-SHA256");
	signer.update(content);
	let auth = signer.sign(privateKey, "base64");
	console.log(`{"msgid":"${msgid}","auth":"${auth}","content":${content}}`);
	socket.emit('message', `{"msgid":"${msgid}","auth":"${auth}","content":${content}}`);

/*verifier = createVerify("RSA-SHA256");
verifier.update(content);
result = verifier.verify(publicKey, sign, "base64");
console.log(result);//true */
}

async function GNSSInfo(socket,lat,lng) {
	// Envia posição dos satelites conforme Lat e long para atualizacão dos rastreadores
	[20,21,35,22].forEach(constellation => {
		fetch(`https://api.n2yo.com/rest/v1/satellite/above/${lat}/${lng}/0/70/${constellation}/&apiKey=${process.env.N2_KEY}`).then(response => response.json()).then(data => {

			var gnss =`{"gnss":"${data.info.category}","satellites":[`;
			data.above.forEach(element => {
				gnss+=`{"name":"${element.satname}","lat":"${element.satlat}","lng":"${element.satlng}","alt":"${element.satalt}","designator":"${element.intDesignator}"},`;
			});
			SendMsg(socket,`GNSS${constellation}`,gnss.slice(0, -1)+`]}`);

		}).catch(error => console.error(error));
	});
}

/****************************************************************************************************/
/* Create and open Redis connection 																*/
/****************************************************************************************************/
const Redis = require('ioredis');
const hub = new Redis({host:process.env.RD_host, port:process.env.RD_port, password:process.env.RD_pass});
const pub = new Redis({host:process.env.RD_host, port:process.env.RD_port, password:process.env.RD_pass});

// Publica STATUS
async function PublishUpdate() {
	GetDate().then(dte => {
		let uptime = Date.parse(dte) - starttime;
		pub.publish('san:server_update','{"name":"'+process.title+'","version":"'+version+'","ipport":"'+process.env.HUBIP+':'+process.env.HUBPort+'","uptime":"'+Math.floor(uptime/60000)+'"}');
	});
}

// Updates server status as soon as it successfully connects
hub.on('connect', function () { PublishUpdate(); GetDate().then(dte =>{ console.log('\u001b[36m'+dte+': \u001b[32mHUB connected.\u001b[0;0m');
																		console.log('\u001b[36m'+dte+': \u001b[32mWaiting clients...\u001b[0;0m');}); });

// Subscribe on chanels
hub.subscribe("san:server_update","san:monitor_update", (err, count) => {
  if (err) {
	console.log('\u001b[36m'+dte+': \u001b[31mFailed to subscribe: '+ err.message +'\u001b[0m');
  } 
});

// Waiting messages
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
/* Create and open MySQL connection																	*/
/****************************************************************************************************/
const mysql = require('mysql2');
const db = mysql.createPool({host:process.env.DB_host, database:process.env.DB_name, user:process.env.DB_user, password:process.env.DB_pass, connectionLimit:10});

// Initialize global variables
var starttime=0,numdev=0,msgsin=0,msgsout=0,bytsin=0,bytsout=0,bytserr=0;

// Update statistics ever 60s
setInterval(function() {
			// Pega data e hora GMT
			let dte = new Date(new Date().getTime()).toISOString().replace(/T/,' ').replace(/\..+/, '');
			// Publish update status
			PublishUpdate();
			// Update database
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
/* Mostra os parâmetros no Log e aguarda conexões													*/
/****************************************************************************************************/
const OS = require('node:os');

GetDate().then(dte => {
	// Save start datetime
	starttime = Date.parse(dte);
	// Show parameters and waiting clients
	console.log('\u001b[36m'+dte+': \u001b[37m================================');
	console.log('\u001b[36m'+dte+': \u001b[37mAPP : ' + process.title + ' ('+version+')');
	console.log('\u001b[36m'+dte+': \u001b[37mIP/Port : ' + process.env.HUBIP + ':' + process.env.HUBPort);
	console.log('\u001b[36m'+dte+': \u001b[37mCPUs: '+ OS.cpus().length);
	console.log('\u001b[36m'+dte+': \u001b[37m================================');});