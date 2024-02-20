require 'json'

module WebSocketManager
	@websockets = {}
	@listeners = {}

	class << self
		def add_connection(id, ws)
			@websockets[id] = {ws: ws, user: nil}
		end

		def get_connection(id)
			@websockets[id]
		end

		def get_connections
			@websockets.map { |id, connection| connection[:ws] }
		end

		def get_user(id)
			@websockets[id].user
		end

		def remove_connection(id)
			@websockets.delete(id)
		end

		def process(ws, message)
			data = JSON.parse(message)

			id = data['id']
			event = data['event']
			payload = data['payload']
			listener = @listeners[event]

			if listener == nil
				return
			end

			result = listener.call(ws, payload)

			if id == nil
				return
			end

			ws.send({id: id, payload: result}.to_json)

		end

		def on(event, &block)
			@listeners[event] = block
		end

		def push(event, payload, clients)
			message = {event: event, payload: payload}.to_json
			clients.each do |client|
				client.send(message)
			end
		end

		def broadcast(message)
			@websockets.each_value do |connection|
				connection[:ws].send(message)
			end
		end
	end
end
