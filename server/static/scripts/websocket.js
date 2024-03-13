(exports => {

	let ws;
	const requests = {};
	const listeners = {};

	const isResponse = message => message.id != null;

	function connectWebSocket() {
		console.log('Connecting');
		ws = new WebSocket(`ws://${window.location.hostname}:3000`);

		// ws.onopen = function() {
		// 	console.log("Connected");
		// 	// ws.send("Hello Server!");
		// };
		// ws.onmessage = function(event) {
		// 	console.log("Received: " + event.data);
		// 	const p = document.createElement('div')
		// 	p.innerText = event.data;
		// 	document.querySelector("#messages").appendChild(p);
		// };
		// ws.onclose = function() {
		// 	console.log("Disconnected");
		// };

		ws.addEventListener('message', incoming => {
			const data = JSON.parse(incoming.data);
			const {id, event, payload} = data;

			// if(id == null)
			// 	console.log(data);

			if(isResponse(data))
				return requests[id](payload);

			if(event === '_handshake') {
				ws.id = payload.id;
				return;
			}

			const listener = listeners[event];

			if(listener == null)
				return;

			listener(payload);
		});

		console.log(ws);
	}

	const checkServerStatus = async () => {
		setTimeout(checkServerStatus, 1000);

		if(ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING))
			return;

		try {
			const response = await fetch(`http://${window.location.hostname}:8080/health`)

			if(!response.ok)
				return;

			connectWebSocket();

		} catch(e) {
		}
	}

	checkServerStatus();

	const on = (event, listener) => {
		if(event.startsWith('_'))
			return console.error(`Event names with leading underscore are reserved for internal events: ${event}`)
		listeners[event] = listener;
	}

	const off = (event) => {
		delete listeners[event];
	}

	const request = (event, payload) => {
		return new Promise(resolve => {
			const id = Math.random().toString(36).substring(7);
			requests[id] = resolve;
			ws.send(JSON.stringify({id, event, payload}));
		});
	}

	const push = (event, payload) => {
		ws.send(JSON.stringify({event, payload}));
	}

	const isSelf = id => id === ws.id;
	const getId = () => ws.id;

	exports.on = on;
	exports.off = off;
	exports.request = request;
	exports.push = push;
	exports.isSelf = isSelf;
	exports.getId = getId;

})(WS = {});
