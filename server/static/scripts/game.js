(exports => {

	let tick = 0;
	let totalAdjustment = 5;

	let eventId = 0;
	let history = [];

	let then = performance.now();
	let target_interval;
	let sleep_time;

	let tick_callback = () => {};

	const animate = () => {
		const now = performance.now();

		const actual_interval = now - then;
		const drift = actual_interval - target_interval
		sleep_time -= drift;

		tick_callback(tick, actual_interval);

		setTimeout(animate, Math.max(0, sleep_time));

		document.querySelector('#fps').textContent = `tick ${tick} `;

		tick++;
		then = now;
	}

	async function init(ticksPerSecond) {
		sleep_time = target_interval = 1000 / ticksPerSecond;

		animate();

		tick = await WS.request('game_get_tick') + totalAdjustment;

		console.log("starting tick", tick);

		setInterval(async () => {
			const response = await WS.request('game_check_tick', tick);
			const {difference} = response;

			// if(difference < 0)
			// 	tick += -difference + 2;
			// if(difference > 2)
			// 	tick -= difference - 2;

			// console.log(response);

			console.log(response.difference, response.client_tick, response.server_tick);

		}, 1000);

		WS.on('game_tick_adjust', adjustment => {
			tick += adjustment;
			totalAdjustment += adjustment;

			document.querySelector('#adj').textContent = `adj ${totalAdjustment} `;
		});

		WS.on('game_packet_dropped', id => {
			history = history.filter(entry => entry.i !== id);
			console.log('dropped packet');
		});
	}

	const sendEvent = (eventName, data) => {
		const payload = {i: eventId, t: tick, e: eventName, d: data};
		history.push(payload);
		WS.push('game_event', payload);
	}

	exports.init = init;
	exports.mod_tick = mod => tick += mod;
	exports.on_tick = callback => tick_callback = callback;
	exports.sendEvent = sendEvent;

})(Game = {});