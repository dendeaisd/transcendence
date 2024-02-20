((exports) => {

	let ws;
	const requests = {};
	const listeners = {};

	const isResponse = message => message.id != null;

	function connectWebSocket() {
		console.log("Connecting");
		ws = new WebSocket("ws://localhost:3000");

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

			if(isResponse(data))
				return requests[id](payload);

			const listener = listeners[event];

			if(listener == null)
				return;

			listener(payload);
		});
	}

	const checkServerStatus = async () => {
		setTimeout(checkServerStatus, 1000);

		if(ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING))
			return;

		try {
			const response = await fetch('http://localhost:8080/health')

			if(!response.ok)
				return;

			connectWebSocket();

		} catch(e) {
		}
	}

	checkServerStatus();

	const on = (event, listener) => {
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

	exports.on = on;
	exports.off = off;
	exports.request = request;
	exports.push = push;

})(WS = {});
