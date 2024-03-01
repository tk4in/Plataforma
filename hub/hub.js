/***************************************************************************************************/
/* HUB		                                                                                         */
/* Para executar use: node hub.js &        		                                                     */
/***************************************************************************************************/
process.title = "hub";
const version = "v1.0.0";

const { GetDate } = require("../utils/utils.js");

/****************************************************************************************************/
/* Le as variáveis de ambiente																		                                  */
/****************************************************************************************************/
require("dotenv").config({ path: "../.env" });

/****************************************************************************************************/
/* Gera as chaves publica e privada para encriptar										                        			*/
/****************************************************************************************************/
const { generateKeyPairSync, createSign, createVerify} = require("node:crypto");
const { publicKey, privateKey } = generateKeyPairSync("rsa", {
  modulusLength: 2048,
  publicKeyEncoding: { type: "pkcs1", format: "pem" },
  privateKeyEncoding: { type: "pkcs1", format: "pem" },
});

/****************************************************************************************************/
/* Cria e abre uma conexão express	 																*/
/****************************************************************************************************/
const app = require("express");
const http = require("http").createServer(app);
http.listen(process.env.HUBPort || 50900);

/****************************************************************************************************/
/* Socket.io      																					*/
/****************************************************************************************************/
const io = require("socket.io")(http, {
  cors: {
    origin: "*",
  },
});

io.on("connection", (socket) => {
  // Trata as menssagens
  socket.on("message", (msg) => {
    // Atualiza contadores
    bytsin=bytsin + msg.length;
    msgsin++;
    // converte em JSON
    let jmsg = JSON.parse(msg);

    /*if (jmsg.auth) {
      verifier = createVerify("RSA-SHA256");
      verifier.update(content);
      result = verifier.verify(publicKey, auth, "base64");
      console.log(result);//true
    }*/
    switch (jmsg.msgid) {
		  case "START":     // Inicializa a sessão
    	    break;

		  case "GNSS":      // Inicializa a sessão

			    GNSSInfo(socket, -23.513346, -46.631134);
			    break;

		  case "HELLO": 	  // Envia nome do app versao e a chave publica para troca de messagens

          SendMsg(socket,"HELLO", `{"msgid":"HELLO","content":{"app":"${process.title}","version":"${version}","pubkey":"${publicKey}"}}`,false)
     	    break;
    }
  });
});

async function SendMsg(socket, msgid, content, secure) {
  if (secure) {
    signer = createSign("RSA-SHA256");
    signer.update(content);
    auth = signer.sign(privateKey, "base64");
    msg = `{"msgid":"${msgid}","auth":"${auth}","content":${content}}`;
  } else {
    msg = `{"msgid":"${msgid}","content":${content}}`;
  }
  // Envia menssagem
  console.log(msg);
  socket.emit("message", msg);
  // Atualiza contadores
  bytsout=bytsout + msg.length;
  msgsout++;
}

async function GNSSInfo(socket, lat, lng) {
  // Envia posição dos satelites conforme Lat e long para atualizacão dos rastreadores
  [20, 21, 35, 22].forEach((constellation) => {
    fetch(`https://api.n2yo.com/rest/v1/satellite/above/${lat}/${lng}/0/70/${constellation}/&apiKey=${process.env.N2_KEY}` ).then((response) => response.json()).then((data) => {
        var gnss = `{"gnss":"${data.info.category}","satellites":[`;
        data.above.forEach((element) => {
          gnss += `{"name":"${element.satname}","lat":"${element.satlat}","lng":"${element.satlng}","alt":"${element.satalt}","designator":"${element.intDesignator}"},`;
        });
        SendMsg(socket, "GNSS", gnss.slice(0, -1) + ']}"}', true)
      }).catch((error) => console.error(error));
  });
}

/****************************************************************************************************/
/* Cria e abre uma conexão Redis	 																                                  */
/****************************************************************************************************/
const Redis = require("ioredis");
const hub = new Redis({host: process.env.RD_host, port: process.env.RD_port, password: process.env.RD_pass});
const pub = new Redis({host: process.env.RD_host, port: process.env.RD_port, password: process.env.RD_pass});

// Publica STATUS
async function PublishUpdate() {
  GetDate().then((dte) => {
    let uptime = Date.parse(dte) - starttime;
    pub.publish( "san:server_update", '{"name":"' + process.title + '","version":"' + version + '","ipport":"' + process.env.HUBIP + ":" + process.env.HUBPort + '","uptime":"' + Math.floor(uptime / 60000) + '"}');
  });
}

// Publica o STATUS assim que se conectar no HUB
hub.on("connect", function () {
  PublishUpdate();
  GetDate().then((dte) => {
    console.log("\u001b[36m" + dte + ": \u001b[32mHUB conectado.\u001b[0;0m");
    console.log("\u001b[36m" + dte + ": \u001b[32mAguardando clientes...\u001b[0;0m");
  });
});

// Se inscreve nos canais para receber comunicações
hub.subscribe("san:server_update", "san:monitor_update", (err, count) => {
  if (err) {
    console.log("\u001b[36m" + dte + ": \u001b[31mFalha na inscrição: " + err.message + "\u001b[0m");
  }
});

// Aguarda messagens dos canais
hub.on("message", (channel, message) => {
  switch (channel) {
    case "san:server_update":
      break;

    case "san:monitor_update":
      io.emit("dev_monitor", message);
      break;
  }
});

/****************************************************************************************************/
/* Cria e abre uma conexão MySQL										                                  							*/
/****************************************************************************************************/
const mysql = require('mysql2');
const db = mysql.createPool({host:process.env.DB_host, database:process.env.DB_name, user:process.env.DB_user, password:process.env.DB_pass, connectionLimit:10});

// Initialize global variables
var starttime = 0, numdev = 0, msgsin = 0, msgsout = 0, bytsin = 0, bytsout = 0, bytserr = 0;

// Grava estatísticas a cada 60s
setInterval(function () {
  // Pega data e hora GMT
  let dte = new Date(new Date().getTime()).toISOString().replace(/T/, " ").replace(/\..+/, "");
  // Publica o STATUS do serviço
  PublishUpdate();
  // Atualiza banco de dados
  db.getConnection(function (err, connection) {
    if (!err) {
      connection.query("INSERT INTO syslog (datlog,server,version,ipport,devices,msgsin,msgsout,bytsin,bytsout,bytserr) VALUES (?,?,?,?,?,?,?,?,?,?)",
        [dte, process.title, version, process.env.SrvIP + ":" + process.env.SrvPort, numdev, msgsin, msgsout, bytsin, bytsout, bytserr],
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
/* Mostra os parâmetros no Log e aguarda conexões						                           							*/
/****************************************************************************************************/
const OS = require("node:os");

GetDate().then((dte) => {
  // Guarda date e hora de início do servidor
  starttime = Date.parse(dte);
  // Mostra parâmetros no LOG
  console.log("\u001b[36m" + dte + ": \u001b[37m================================");
  console.log("\u001b[36m" + dte + ": \u001b[37mAPP : " + process.title + " (" + version + ")");
  console.log("\u001b[36m" + dte + ": \u001b[37mIP/Port : " + process.env.HUBIP + ":" + process.env.HUBPort);
  console.log("\u001b[36m" + dte + ": \u001b[37mCPUs: " + OS.cpus().length);
  console.log("\u001b[36m" + dte + ": \u001b[37m================================");
});