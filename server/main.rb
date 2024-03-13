require 'em-websocket'
require 'em-http-server'
require 'mime/types'
require_relative 'websocket_manager'
require_relative 'timer'

def path_get_absolute(fspath)
	absolute_path = File.expand_path(fspath)
	# absolute_path += File::SEPARATOR unless absolute_path.end_with?(File::SEPARATOR)

	return absolute_path
end

def path_contains_base_path?(target_path, base_path)
	# Expand both paths to their absolute forms
	absolute_target_path = path_get_absolute(target_path)
	absolute_base_path = path_get_absolute(base_path)

	# Check if the target path starts with the base path
	return absolute_target_path.start_with?(absolute_base_path)
end

WebSocketManager.on('message') do |connection, payload|
	WebSocketManager.push('message', payload, WebSocketManager.get_connections)
end

WebSocketManager.on('ping') do |connection, payload|
	payload
end

WebSocketManager.on('slider') do |connection, payload|
	WebSocketManager.broadcast(connection[:id], 'slider', payload)
end

WebSocketManager.on('move') do |connection, payload|
	WebSocketManager.broadcast(connection[:id], 'move', payload)
end

$ws_port = 3000
$http_port = 8080
$static_dir = path_get_absolute('./static')

EM.run do
	# WebSocket Server
	EM::WebSocket.run(host: "0.0.0.0", port: $ws_port) do |ws|
		ws.onopen do
			id = ws.object_id
			puts "Client connected #{id}"
			WebSocketManager.add_connection(id, ws)
			WebSocketManager.push('_handshake', {id: id}, [WebSocketManager.get_connection(id)])
			WebSocketManager.push('connect', {id: id}, WebSocketManager.get_connections)
			WebSocketManager.push('list', {ids: WebSocketManager.get_ids - [id]}, [WebSocketManager.get_connection(id)])
			# WebSocketManager.broadcast("client " + id.to_s + " connected")
		end

		ws.onmessage do |msg|
			puts "Received message: #{msg}"
			WebSocketManager.process(ws, msg)
		end

		ws.onclose do
			puts "Client disconnected"
			WebSocketManager.remove_connection(ws.object_id)
			WebSocketManager.push('disconnect', {id: ws.object_id}, WebSocketManager.get_connections)
			# WebSocketManager.broadcast("client " + ws.object_id.to_s + " disconnected")
		end

		ws.onerror do |error|
			puts "Error occurred: #{error}"
		end
	end

	puts "WebSocket server started on ws://0.0.0.0:#{$ws_port}"

	# HTTP Server
	class HttpServer < EM::HttpServer::Server
		def process_http_request
			# You can access the HTTP method: @http_request_method ('GET', 'POST', etc.)
			# The URI: @http_path_info
			# Query string: @http_query_string
			# And the post content: @http_post_content

			response = EM::DelegatedHttpResponse.new(self)

			puts "Received HTTP request: #{@http_request_method} #{@http_request_uri}"
			uri = @http_request_uri

			# Simple routing example
			case uri
			when '/'
				response.status = 200
				response.content_type 'text/html'
				file_path = File.join($static_dir, 'index.html')
				puts file_path
				puts File.exist?(file_path)
				if File.exist?(file_path)
					response.content = File.read(file_path)
				else
					response.status = 404
					response.content_type 'text/plain'
					response.content = 'File Not Found'
				end
			when '/health'
				response.status = 200
				response.content_type 'text/plain'
				response.content = 'OK'
			else
				absolute_path = path_get_absolute(File.join($static_dir, uri))
				if !path_contains_base_path?(absolute_path, $static_dir)
					response.status = 400
					response.content_type 'text/plain'
					response.content = 'Bad Request'
				elsif File.exist?(absolute_path) && File.readable?(absolute_path)
					response.status = 200
					response.content_type MIME::Types.type_for(absolute_path).first.content_type
					response.content = File.read(absolute_path)
				else
					response.status = 404
					response.content_type 'text/plain'
					response.content = 'File Not Found'
				end
			end

			# puts "Sending response..."
			response.send_response
		end
	end

	# Start the HTTP server
	EM.start_server "0.0.0.0", $http_port, HttpServer
	puts "HTTP server started on http://0.0.0.0:#{$http_port}"

	# start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
	# tick = 0
	# target = 20
	# desired_interval = 1.0 / target
	# offset = 0

	# adj_tick = 0
	# adj_total = 0

	# def precise_sleep(target_interval, offset)
	# 	if target_interval <= 0
	# 		return
	# 	end

	# 	start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

	# 	loop do
	# 		now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
	# 		break if now - start >= target_interval + offset
	# 		# Sleep briefly to prevent excessive CPU usage
	# 		sleep(0.001)
	# 	end
	# end

	# loop do
	# 	start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)


	# 	end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

	# 	precise_sleep(desired_interval - end_time + start_time, offset)

	# 	real = tick / (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start)
	# 	adj_total += real - target

	# 	if adj_tick >= target * 3 then
	# 		offset = adj_total / adj_tick * 0.01
	# 		adj_tick = 0
	# 		adj_total = 0
	# 		puts "adjust"
	# 	end

	# 	puts "#{format("%-18f", real)} #{offset}"
	# 	tick += 1
	# 	adj_tick += 1

	# end

	# def precise_ticker(n)
	# 	target_interval = 1.0 / n
	# 	last_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
	# 	sleep_time = target_interval

	# 	loop do
	# 		# Perform the tick action
	# 		yield

	# 		now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
	# 		actual_interval = now - last_time
	# 		last_time = now

	# 		# Calculate the drift
	# 		drift = actual_interval - target_interval

	# 		# Adjust sleep_time to compensate for the drift
	# 		sleep_time -= drift

	# 		# Ensure sleep_time is not negative
	# 		sleep_time = [0, sleep_time].max

	# 		sleep(sleep_time) if sleep_time > 0
	# 	end
	# end

	# # Example usage: Tick 10 times per second (10Hz)
	# start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
	# tick = 0

	# precise_ticker(60) do
	# 	real = tick / (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start)
	# 	# puts "#{format("%-10f", real)} Hz #{tick} ticks"
	# 	tick += 1
	# end

	Timer.run(60)

	def make_timer_hook
		start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		tick = 0
		queue = {}

		pos = {x: 0, y: 0}

		WebSocketManager.on('game_set_pos') do |connection, payload|
			pos[:x] = payload['x']
			pos[:y] = payload['y']
			puts pos
		end

		WebSocketManager.on('game_event') do |connection, payload|
			client_tick = payload['t']

			# notify client of dropped message
			if client_tick < tick then
				puts "dropped packet | c #{client_tick} s #{tick} d #{client_tick - tick}"
				WebSocketManager.push('game_packet_dropped', payload['i'], [connection])
				next
			end

			entry = {connection: connection, payload: payload}

			if queue[client_tick] == nil then
				queue[client_tick] = [entry]
			else
				queue[client_tick].push(entry)
			end
		end

		WebSocketManager.on('game_get_tick') do |connection, payload|
			tick
		end

		WebSocketManager.on('game_check_tick') do |connection, payload|
			difference = payload - tick
			adjustment = 0

			if difference < 2 then
				adjustment = -difference + 2;
			elsif difference > 4
				adjustment = -difference + 2;
			end

			if adjustment != 0 then
				WebSocketManager.push('game_tick_adjust', adjustment, [connection])
			end

			{client_tick: payload, server_tick: tick, difference: difference}
		end

		lambda do
			real = tick / (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start)

			entries = queue[tick]

			if entries != nil then

				for entry in entries
					connection = entry[:connection]
					payload = entry[:payload]

					client_tick = payload['t']
					input = payload['d']

					step = 3

					if input[0] == 1 then
						pos[:y] = [0, pos[:y] - step].max
						# puts 'move up'
					end
					if input[1] == 1 then
						pos[:x] = [0, pos[:x] - step].max
						# puts 'move left'
					end
					if input[2] == 1 then
						pos[:y] = [500, pos[:y] + step].min
						# puts 'move down'
					end
					if input[3] == 1 then
						pos[:x] = [500, pos[:x] + step].min
						# puts 'move right'
					end

					WebSocketManager.push('game_validation', {t: client_tick, p: pos}, [connection])
				end

				queue.delete(tick)

			end

			# puts "#{format("%-10f", real)} Hz, #{tick} ticks"
			tick += 1
		end
	end

	Timer.add_hook(&make_timer_hook)

	puts "Server started"

end
