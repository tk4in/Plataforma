/****************************************************************************************************/
/* Root     																						*/
/****************************************************************************************************/
const express = require("express");
const router = express.Router();

const { GetDate, GetUSID} = require("../utils/utils.js");
const { randomBytes } = require("node:crypto");

router.get('/', (req, res, next) => {

  // Inicializa a sessao
  let session = {
    cookies: {},
    gets: {},
    remoteAddress: {},
    err: 0,
    name: "",
    USID: "teste",
  };

  // Verifica se a linguagem e uma da válidas se nao for seta com inglês
  let langs = ["pt-BR", "en-US", "zh-CN"];
  if (!langs.includes(session.lang)) {
    session.lang = "pt-BR";
  }

  nonce = randomBytes(16).toString("hex");

  res.writeHead(200, {
    "access-control-allow-methods": "GET,POST",
    "access-control-allow-origin": "'https://" + process.env.WEBAddr + "'",
    "cache-control": "no-cache",
    "content-security-policy":
      "default-src https: 'self'; base-uri 'self'; script-src 'report-sample' 'nonce-" + nonce +
      "' cdnjs.cloudflare.com/ajax/libs/ " + process.env.CDNAddr +
      "/; style-src 'self' 'report-sample' cdnjs.cloudflare.com/ajax/libs/ " + process.env.CDNAddr +
      "/; object-src 'none'; frame-src 'self'; frame-ancestors 'none'; img-src 'self' data: https: " + process.env.CDNAddr +
      "; font-src cdnjs.cloudflare.com/ajax/libs/font-awesome/; connect-src 'self' " + process.env.CDNAddr + "/; form-action 'self'; media-src 'self'; worker-src 'self'",
      "content-type": "text/html; charset=UTF-8",
    date: new Date().toUTCString(),
    "permissions-policy": 'geolocation=(self "https://' + process.env.WEBAddr + '")',
    "referrer-policy": "no-referrer",
    "Report-To": '{"group":"default","max_age":31536000,"endpoints":[{"url":"https://' + process.env.CDNAddr + '/report-to"}],"include_subdomains":true}',
    "set-cookie": process.env.SessID + "=" + session.USID + "; Domain=" + process.env.WEBAddr + "; Path=/; Samesite=Strict; Secure; HttpOnly",
    "strict-transport-security": "max-age=31536000; includeSubDomains; preload",
    vary: "Accept-Encoding",
    "x-content-type-options": "nosniff",
    "x-frame-options": "DENY",
    "x-permitted-cross-domain-policies": "none", 
    "x-xss-protection": "1; mode=block",
  });

  // Le a linguagem
  let lang = require("./lang/" + session.lang + "/root");

  // Html
  res.write(
    "<!DOCTYPE html><html itemscope itemtype='http://schema.org/WebSite'; lang=" + session.lang +
      "><head><meta name='viewport' content='width=device-width, initial-scale=1'><meta charset=utf-8><title itemprop=name>" + lang._TITLE +
      "</title><link rel=dns-prefetch href=https://" + process.env.CDNAddr +
      "><link rel=canonical href=https://" + process.env.WEBAddr +
      " itemprop=url><link rel=icon href='https://" + process.env.CDNAddr + '/' + process.env.AppID +
      "/img/logo.png' itemprop=image><link rel=preload href='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/webfonts/fa-regular-400.woff2' as=font type='font/woff2' crossorigin=anonymous><link rel=preload href='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/webfonts/fa-solid-900.woff2' as=font type='font/woff2' crossorigin=anonymous><meta name=description content='" + lang._DESCRIPTION +
      "' itemprop=description><meta name=keywords content='" + lang._KEYWORDS +
      "'><meta name=apple-mobile-web-app-capable content=yes><meta name=apple-mobile-web-app-status-bar-style content=black-translucent><link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap.min.css' integrity='sha512-jnSuA4Ss2PkkikSOLtYs8BlYIeeIK1h99ty4YfvRPAlzr377vr3CXDb7sb7eEEBYjDtcYj+AjBH3FLv5uSJuXg==' crossorigin=anonymous /><link href='https://" + process.env.CDNAddr + '/' + process.env.AppID + "/css/style.css' rel=stylesheet crossorigin=anonymous></head><body>"
  );

  // Block
  res.write(
    "<div class=loader-wrap id=loader-wrap><div class=blocks><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div><div class=block></div></div></div>"
  );

  // Body
  res.write(
    "<section id=content class=login-content><div id=login-box class='login-box" + (session.err === 4 ? " flipped" : "") +
    "'><form class=login-form action=login method=post name=logform'><h3 class=login-head><i class='fa fa-fw fa-lg fa-user'></i>" + lang._LOGIN +
    "</h3><div class=qr-form id=qrid><div class=form-group><label for=login>" + lang._NAME +
    "</label><input class=form-control name=login id=login value='" + session.name + "'"
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
    " autocomplete=off></div><div class=form-group><label for=pass>" + lang._PASS +
    "</label><input class=form-control name=pass id=pass type=password></div><div class=form-group><div class=utility><div class=animated-checkbox><label><input type=checkbox name=rm><span class=label-text>" + lang._STAY +
    "</span></label></div><p class='semibold-text mb-2'><a href='#' name=flip>" + lang._FORGOT +
    "<i class='fa fa-fw fa-angle-right'></i></a></p></div></div><div class='form-group btn-container'><button type=submit class='btn btn-primary btn-block snd' name=log id=log><i class='fa fa-fw fa-lg fa-sign-in-alt'></i>" + lang._SEND +
    "</button></div></div></form><form class=forget-form action=register method=post><h3 class=login-head><i class='fa fa-fw fa-lg fa-lock'></i>" + lang._FORGOTPASS +
    "</h3><div class=form-group><label for=email>" + lang._EMAIL +
    "</label><input class=form-control name=email id=email value='" + session.name +
    "' autocomplete=off></div><div class='form-group mt-3'><p class='semibold-text mb-0'><a href='#' name=flip><i class='fa fa-fw fa-angle-left'></i>" + lang._BACK +
    "</a></p></div><div class='form-group btn-container'><button type=button class='btn btn-primary btn-block snd' name=fgt><i class='fa fa-fw fa-lg fa-unlock'></i>" + lang._SEND2 +
    "</button></div></form><h2 class=cipher><i class='fa fa-fw fa-lock'></i>" + lang._CIPHER + "</h2></div></section>"
  );

  // Scripts
  res.write(
    "<script src='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/js/bootstrap.bundle.min.js' integrity='sha512-7Pi/otdlbbCR+LnW+F7PwFcSDJOuUJB3OxtEHbg4vSMvzvJjde4Po1v4BR9Gdc9aXNUNFVUY+SK51wWT8WF0Gg==' crossorigin=anonymous></script><script nonce=" + nonce +
    ">const es=document.getElementsByName('flip');Array.from(es).forEach(function (e){e.addEventListener('click', function(){document.getElementById('login-box').classList.toggle('flipped');});});document.getElementById('log').addEventListener('click', function(){document.getElementById('content').classList.add('blured');document.getElementById('loader-wrap').style.display='block';});"
  );
  res.end("</script></body></html>");

});

module.exports = router;