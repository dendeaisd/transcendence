const http = require('http');
const express = require('express');
const websocket = require('socket.io');

const port = 4000;

const app = express();
const server = http.createServer(app);
const io = websocket(server);

app.get('/', (req, res) => {
	res.sendFile(__dirname + '/index.html');
});

server.listen(port, () => {
	console.log(`Nodejs listening at http://localhost:${port}`);
});

io.on('connection', socket => {
	console.log('A user connected');
	socket.on('disconnect', () => {
		console.log('A user disconnected');
	});
	socket.on('chat message', msg => {
		io.emit('chat message', msg);
	});
	socket.on('game state', state => {
		io.emit('game state', state);
	});
});