/****************************************************************************************************/
/* Main     																						*/
/****************************************************************************************************/
const express = require("express");
const router = express.Router();

const { GetDate, GetUSID} = require("../utils/utils.js");
const { randomBytes } = require("node:crypto");

router.get("/main", (req, res, next) => {
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
    "access-control-allow-origin": "'https://" + process.env.AppAddr + "'",
    "cache-control": "no-cache",
    "content-Security-Policy":
      "default-src https: 'self'; base-uri 'self'; script-src 'report-sample' 'nonce-" +
      nonce +
      "' 'self' 'unsafe-eval' cdnjs.cloudflare.com/ajax/libs/ api.mapbox.com/ www.gstatic.com/draco/ ajax.googleapis.com/ajax/libs/ " +
      process.env.CDNAddr +
      "/; style-src 'self' 'unsafe-hashes' 'unsafe-inline' 'report-sample' cdnjs.cloudflare.com/ajax/libs/ fonts.googleapis.com/ fonts.gstatic.com/ api.mapbox.com/ " +
      process.env.CDNAddr +
      "/; object-src 'none'; frame-src 'self'; frame-ancestors 'none'; child-src 'self'; img-src 'self' data: https: " +
      process.env.CDNAddr +
      "/; font-src fonts.gstatic.com/ fonts.googleapis.com/ cdnjs.cloudflare.com/ajax/libs/font-awesome/; connect-src 'self' blob: *.mapbox.com/ www.gstatic.com/draco/ " +
      process.env.HUBAddr + ":" + process.env.HUBPort + "/ " +  process.env.CDNAddr +
      "/; form-action 'self'; media-src 'self'; worker-src 'self' blob: https: " +  process.env.CDNAddr +"/",
    "content-type": "text/html; charset=UTF-8",
    date: new Date().toUTCString(),
    "permissions-policy": 'geolocation=(self "https://' + process.env.AppAddr + '")',
    "referrer-policy": "no-referrer",
    "Report-To": '{"group":"default","max_age":31536000,"endpoints":[{"url":"https://' + process.env.CDNAddr + '/report-to"}],"include_subdomains":true}',
    "set-cookie": process.env.SessID + "=" + session.USID + "; Domain=" + process.env.AppAddr + "; Path=/; Samesite=Strict; Secure; HttpOnly",
    "strict-transport-security": "max-age=31536000; includeSubDomains; preload",
    vary: "Accept-Encoding",
    "x-content-type-options": "nosniff",
    "x-frame-options": "DENY",
    "x-permitted-cross-domain-policies": "none",
    "x-xss-protection": "1; mode=block",
  });

  // Le a linguagem
  let lang = require("./lang/" + session.lang + "/main");

  // Html
  res.write(
    "<!DOCTYPE html><html lang=" +
      session.lang +
      " data-footer='true' data-override='{'attributes': {'placement': 'vertical','layout': 'fluid' }, 'showSettings':false, 'storagePrefix': '" +
      process.env.AppID +
      "'}'><head><meta charset=utf-8><title>" +
      lang._TITLE +
      "</title><link rel='dns-prefetch' href=https://" +
      process.env.CDNAddr +
      "><link rel=icon href='https://" +
      process.env.CDNAddr + '/' + process.env.AppID + "/img/logo.png'><meta name='viewport' content='width=device-width, initial-scale=1'><meta name=apple-mobile-web-app-capable content=yes><meta name=apple-mobile-web-app-status-bar-style content=black-translucent><link href='https://fonts.googleapis.com/css2?family=Russo+One&family=Sarala:wght@700&display=swap' rel='stylesheet'>"
  );
  res.write(
    "<link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap.min.css' integrity='sha512-jnSuA4Ss2PkkikSOLtYs8BlYIeeIK1h99ty4YfvRPAlzr377vr3CXDb7sb7eEEBYjDtcYj+AjBH3FLv5uSJuXg==' crossorigin=anonymous /><link rel='stylesheet' href='https://api.mapbox.com/mapbox-gl-js/v3.2.0/mapbox-gl.css' crossorigin=anonymous />"
  );
  res.write(
    "<link rel=stylesheet href='https://" +
    process.env.CDNAddr + '/' + process.env.AppID + "/css/main.css#" + nonce + "' crossorigin=anonymous></head><body><div class='baroff' id='baroff'>" +
    lang._WAITCONECT + "</div>"
  );

  // GNSS Desktop
  res.write("<div id='gnssgroup' class='gnssgroup'>");

  // GPS
  res.write(
    "<div class='gnsstit'><i class='fa fa-fw fa-satellite'></i>" +
      lang._GPS +
      "</div><div class='gnssbox'><div class='row row-cols-4 gnsshead'><div class='col-5 gnssline'>" +
      lang._NAME +
      "</div><div class='col-2 gnssline d-flex flex-row-reverse'>" +
      lang._LAT +
      "</div><div class='col-2 gnssline d-flex flex-row-reverse'>" +
      lang._LONG +
      "</div><div class='col-3 gnssline'>" +
      lang._DESIGNATOR +
      "</div></div><div class='row row-cols-4' id='gnssgps'></div></div>"
  );

  // GLONASS
  res.write(
    "<div class='gnsstit'><i class='fa fa-fw fa-satellite'></i>" +
      lang._GLONASS +
      "</div><div class='gnssbox'><div class='row row-cols-4 gnsshead'><div class='col-5 gnssline'>" +
      lang._NAME +
      "</div><div class='col-2 gnssline d-flex flex-row-reverse'>" +
      lang._LAT +
      "</div><div class='col-2 gnssline d-flex flex-row-reverse'>" +
      lang._LONG +
      "</div><div class='col-3 gnssline'>" +
      lang._DESIGNATOR +
      "</div></div><div class='row row-cols-4' id='gnssglonass'></div></div>"
  );

  // BEIDOU
  res.write(
    "<div class='gnsstit'><i class='fa fa-fw fa-satellite'></i>" +
      lang._BEIDOU +
      "</div><div class='gnssbox'><div class='row row-cols-4 gnsshead'><div class='col-5 gnssline'>" +
      lang._NAME +
      "</div><div class='col-2 gnssline d-flex flex-row-reverse'>" +
      lang._LAT +
      "</div><div class='col-2 gnssline d-flex flex-row-reverse'>" +
      lang._LONG +
      "</div><div class='col-3 gnssline'>" +
      lang._DESIGNATOR +
      "</div></div><div class='row row-cols-4' id='gnssbeidou'></div></div>"
  );

  // GALILEO
  res.write(
    "<div class='gnsstit'><i class='fa fa-fw fa-satellite'></i>" +
      lang._GALILEO +
      "</div><div class='gnssbox'><div class='row row-cols-4 gnsshead'><div class='col-5 gnssline'>" +
      lang._NAME +
      "</div><div class='col-2 gnssline d-flex flex-row-reverse'>" +
      lang._LAT +
      "</div><div class='col-2 gnssline d-flex flex-row-reverse'>" +
      lang._LONG +
      "</div><div class='col-3 gnssline'>" +
      lang._DESIGNATOR +
      "</div></div><div class='row row-cols-4' id='gnssgalileo'></div></div></div>"
  );

  // Content
  res.write(
    "<div id='content' class='content d-none'><div class='search_div noselect'><div id='barsid' class='bars_icon noselect'><i class='fa fa-fw fa-bars'></i></div><input id='searchbox' type='search' placeholder='" +
      lang._SEARCH +
      "' /><div class='search_icon noselect'><i class='fa fa-fw fa-search'></i></div></div><div class='controls'><div class='switch_style'><img id='street_style' loading='lazy' alt='Street layer' src='https://" +
      process.env.CDNAddr + '/' + process.env.AppID + "/img/street.jpg'><img id='satellite_style' loading='lazy' alt='Satellie layer' class='d-none' src='https://" +
      process.env.CDNAddr + '/' + process.env.AppID + "/img/satellite.jpg'></div></div></div>"
  );

  // Mapa
  res.write("<div id='map' class='map'></div>");

  // Scripts
  res.write("<script src='https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/js/bootstrap.bundle.min.js' integrity='sha512-7Pi/otdlbbCR+LnW+F7PwFcSDJOuUJB3OxtEHbg4vSMvzvJjde4Po1v4BR9Gdc9aXNUNFVUY+SK51wWT8WF0Gg==' crossorigin=anonymous></script><script src='https://api.mapbox.com/mapbox-gl-js/v3.2.0/mapbox-gl.js' integrity='sha512-+f5zHh0q6pj9rhdxgaL5u6H+PnKADOwJSNfQM9NcavVq4y3GnzoRqoVih4Exd//uzdqE7XqnjtQyfr0GuVId2A==' crossorigin=anonymous></script><script src='https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.7.4/socket.io.min.js' integrity='sha512-skuhu6jj+sQnhLq1Txsack8VfnIrX8wL+MTFilYlFFT/NuLJm7eya7zOROs39Jy5cjASMEWqxLzijRVmKhsqWQ==' crossorigin=anonymous></script>" +
      "<script type module src='https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js' integrity='sha512-7aWZDAF0AfUGit0ugd2rk8PxytqMiqaEZnUcXmmH0OcF/aGnGa0uQou8MXJthNjNpIC8yI9G9sWvMXXbn0boxg==' crossorigin=anonymous></script>" +
      "<script nonce=" + nonce +
      ">const accessToken='" + process.env.accessToken +
      "';const CDNAddr='https://" + process.env.CDNAddr +
      "/';const HUBAddr='https://" + process.env.HUBAddr + ':' + process.env.HUBPort +
      "';const AppID='" + process.env.AppID +
      "';const USID='" + session.USID +
      "';</script><script defer src='https://" + process.env.CDNAddr + "/" + process.env.AppID + "/jslib/" + process.env.AppVersion + "/mb.js#" + nonce + "' crossorigin=anonymous></script>"
  );
  res.end("</body></html>");
});

module.exports = router;