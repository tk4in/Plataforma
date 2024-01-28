const start = {center: [0, 0], pitch: 0, bearing: 0, zoom: 2.1};
//const end = {center: [-46.633347,-23.550464], zoom: 18, bearing: 164, pitch: 58};
const end = {center: [-46.631134,-23.513346], zoom: 17.4, bearing: -49, pitch:65};
const streetStyle = 'mapbox://styles/mapbox/standard';
const satelliteStyle = 'mapbox://styles/mapbox/satellite-streets-v12';
let mapStyle = 'satellite';
let connected = false;
let fly_to = 'none';

mapboxgl.accessToken = accessToken;
var map = new mapboxgl.Map({	
	container: 'map',
	style: satelliteStyle,
	center: [0, 0], pitch: 0, bearing: 0, zoom: 2.1,
	minZoom:2.1, maxZoom:20,
	scrollZoom: false,
	dragPan: false,
	doubleClickZoom: false,
	dragRotate: false,
	touchZoomRotate: false,
	hash: true,
	config: {lightPreset:'dusk', showPOILabels: false}
});

function change_map_style(id) {
	if (mapStyle != id) {
		mapStyle = id;
		switch(id) {
            	case 'street':
                	map.setStyle(streetStyle);
                	document.getElementById("street_style").classList.add("d-none");
                	document.getElementById("satellite_style").classList.remove("d-none");
                	break;
            	case 'satellite':
               		map.setStyle(satelliteStyle);
                	document.getElementById("satellite_style").classList.add("d-none");
            	    document.getElementById("street_style").classList.remove("d-none");
        	        break;
		}
	}
}
  
function toDashboard() {
	change_map_style('satellite');
	document.getElementById("content").classList.add("d-none");
	document.getElementById("gnssgroup").classList.remove("d-none");
	map['scrollZoom'].disable();
	map['dragPan'].disable();
	map['doubleClickZoom'].disable();  
	map['dragRotate'].disable();
	map['touchZoomRotate'].disable();
	document.getElementsByClassName("mapboxgl-ctrl-attrib")[0].classList.add("d-none");
	document.getElementsByClassName("mapboxgl-ctrl-logo")[0].classList.add("d-none");
	map.flyTo({ ...start, duration: 16000, essential: true});
	fly_to='dashboard';
}

function toMap() {
	document.getElementById("gnssgroup").classList.add("dn-easy");
	document.getElementById("baroff").classList.add("d-none");
	map['scrollZoom'].enable();
	map['dragPan'].enable();	
	map['doubleClickZoom'].enable();
	map['dragRotate'].enable();
	map['touchZoomRotate'].enable();
	document.getElementById("content").classList.remove("d-none");
	document.getElementsByClassName("mapboxgl-ctrl-attrib")[0].classList.remove("d-none");
	document.getElementsByClassName("mapboxgl-ctrl-logo")[0].classList.remove("d-none");
	map.flyTo({ ...end, duration: 16000, essential: true});
	fly_to='map';
}

function addpoint(img,cor,latlng,street,desc) {
	const el = document.createElement('div');
	el.innerHTML='<div class="marker" style="--background-base: '+cor+';"><div class="title"><img class="imgstreet" title="'+desc+'" src="'+street+'" width="19em" height="12em"><span class="descstreet">'+desc+'</span></div><div class="marker-wrapper"><div class="pin"><div class="image" style="background-image: url('+img+');"></div></div></div></div>';
	new mapboxgl.Marker({anchor:"bottom",element:el,draggable: false}).setLngLat(latlng).addTo(map);
}

function rotateCamera(timestamp) {
	// clamp the rotation between 0 -360 degrees
	// Divide timestamp by 100 to slow rotation to ~10 degrees / sec
	map.rotateTo((timestamp / 200) % 360, { duration: 0 });
	// Request the next frame of the animation.
	requestAnimationFrame(rotateCamera);
}

function spinGlobe() {
	fly_to='spinGlobe';
	const secondsPerRevolution = 120;
	let distancePerSecond = 360 / secondsPerRevolution;
	const center = map.getCenter();
	center.lng -= distancePerSecond;
	// Smoothly animate the map over one second.
	// When this animation is complete, it calls a 'moveend' event.
	map.easeTo({ center, duration: 1000, easing: (n) => n });
}

map.on('moveend', () => {	
	switch(fly_to) {
            case 'spinGlobe':
				spinGlobe();
				break;

			case 'map':
				document.getElementById("gnssgroup").classList.add("d-none");
				//document.getElementById("baroff").classList.add("d-none");
				change_map_style('street');
				fly_to='none';
				break;

			case 'dashboard':
				document.getElementById("gnssgroup").classList.remove("dn-easy");
				if (!connected)	{document.getElementById("baroff").classList.remove("d-none");}
				spinGlobe();
				break;
	}		
});

map.on('load', () => {
	if (!connected) {
		document.getElementsByClassName("mapboxgl-ctrl-attrib")[0].classList.add("d-none");
		document.getElementsByClassName("mapboxgl-ctrl-logo")[0].classList.add("d-none");
	}

	map.setFog({
		color: 'rgb(186, 210, 235)', // Lower atmosphere
		'high-color': 'rgb(36, 92, 223)', // Upper atmosphere
		'horizon-blend': 0.02, // Atmosphere thickness (default 0.2 at low zooms)
		'space-color': 'rgb(11, 11, 25)', // Background color
		'star-intensity': 0.5 // Background star brightness (default 0.35 at low zoooms )
	});
	
	addpoint(cdnAddr+'img/logo.png','#555555',[-46.638335,-23.538745, 0],'https://developers.google.com/static/maps/images/landing/hero_streetview_static_api.png','Planeta GPS');
	addpoint(cdnAddr+'img/Targestar-favicon.png','#f92e6e',[114.518059,23.117404, 0],'https://momiji.edu.vn/storage/ntdvn-tret.jpg','TargeStar');
	
	if ('caches' in window) {
		const urls = [cdnAddr+"3d/air/air-zVuA.glb", cdnAddr+"3d/air/air-oBEWt.glb", cdnAddr+"3d/air/air-oAZWG.glb"];

		caches.open("tk4in-models").then((cache) => {
			cache.addAll(urls).then(() => console.log("Data added to cache.")).catch((error) => console.error("Error adding data to cache:", error));
		});
	}
});

map.on('style.load', function () {
	if (mapStyle == 'street') {
		map.addSource('mysource', {
					type: 'geojson',
					data: {
						'type': 'FeatureCollection',
						'features': [
							{
								'type': 'Feature',
								'id': '14bis',
								'geometry': {'coordinates': [-46.62944, -23.51436],
								'type': 'Point'
								},
							'properties': {}
							}
						]
					}
		});

		map.addModel('14bis', cdnAddr+'3d/air/air-zVuA.glb');
		map.addModel('circus', cdnAddr+'3d/air/air-6WNAp.glb');
		map.addModel('airtrump', cdnAddr+'3d/air/air-oAZWG.glb');
		//map.addModel('mig29', cdnAddr+'3d/air/air-oJwFv.glb');
		//map.addModel('mig29h', cdnAddr+'3d/air/mig_29_9-13.glb');
	
		map.addLayer({
                    'id': 'modellayer',
                    'type': 'model',
                    'source': 'mysource',
                    'layout': {
                        'model-id': '14bis',
					},
                    'paint': {
                       'model-scale': [ 1, 1, 1],
					   'model-rotation': [0,0,50]
					},
				});
				
		map.getLayer('modellayer').scope = '';
	
		// hide the standard style trees layer
		/*const treesLayerId = map.style._order.find((id) => map.style.getLayer(id).type === 'model' && id.startsWith("trees"));
		if (treesLayerId) {
			map.setLayoutProperty(treesLayerId, 'visibility', 'none');
		}*/
	}
});

document.getElementById("street_style").addEventListener("click", function(){change_map_style('street')});
document.getElementById("satellite_style").addEventListener("click", function(){change_map_style('satellite')});
spinGlobe();

/********************************************************/
/* IOsocket												*/
/********************************************************/
var socket = io.connect(hubAddr, {
	'reconnection': true,
	'reconnectionDelay': 3000,
	'reconnectionAttempts': 100
});

socket.on('message', function (msg) {
	let jmsg = JSON.parse(msg);
	switch (jmsg.msgid) {
		case 'START':



			socket.emit('session', '{"token1":"'+firstToken+'"}');


			break;

		case 'START':



			connected=true;
			toMap();
			break;
	}
});

socket.on('disconnect',function() {
	connected=false;
	toDashboard();
});

socket.on('connect',function() {
	
});

/*map.addControl(
	new mapboxgl.GeolocateControl({
		positionOptions: {
		enableHighAccuracy: true
	},
	// When active the map will receive updates to the device's location as it changes.
	trackUserLocation: true,
	// Draw an arrow next to the location dot to indicate which direction the device is heading.
	showUserHeading: true
	})
,'bottom-right');
*/
	

//function At(t){const e=t.params.length?`?${t.params.join("&")}`:"";return mycache(`${t.protocol}://${t.authority}${t.path}${e}`);}
/*function mycache(t){
	if (t.startsWith('https://api.mapbox.com/v4/')) {
		let e = t.split('?')[0];
//		u = "https://tk4.in/map/"+e.substring(26);
		let k = e.substring(26);
		k = k.substr(k.indexOf('/')+1);
		let v = localStorage.getItem(k);
		if (v==='') {v=1} else {v++};
		localStorage.setItem(k, v);
	}
	return t;
}*/