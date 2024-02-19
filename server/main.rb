require 'em-websocket'
require 'em-http-server'
require_relative 'websocket'

ws_port = 3000
http_port = 8080

EM.run do
	# WebSocket Server
	EM::WebSocket.run(host: "0.0.0.0", port: ws_port) do |ws|
		ws.onopen do
			puts "Client connected #{ws.object_id}"
			WebSocketManager.add_connection(ws.object_id, ws)
			WebSocketManager.broadcast("client " + ws.object_id.to_s + " connected")
		end

		ws.onmessage do |msg|
			puts "Received message: #{msg}"
			WebSocketManager.broadcast("client " + ws.object_id.to_s + " " + msg)
		end

		ws.onclose do
			puts "Client disconnected"
			WebSocketManager.remove_connection(ws.object_id)
			WebSocketManager.broadcast("client " + ws.object_id.to_s + " disconnected")
		end

		ws.onerror do |error|
			puts "Error occurred: #{error}"
		end
	end

	puts "WebSocket server started on ws://0.0.0.0:#{ws_port}"

	# HTTP Server
	class HttpServer < EM::HttpServer::Server
		def process_http_request
			# You can access the HTTP method: @http_request_method ('GET', 'POST', etc.)
			# The URI: @http_path_info
			# Query string: @http_query_string
			# And the post content: @http_post_content

			response = EM::DelegatedHttpResponse.new(self)

			puts "Received HTTP request: #{@http_request_method} #{@http_request_uri}"

			# Simple routing example
			case @http_request_uri
			when '/'
				response.status = 200
				response.content_type 'text/html'
				file_path = '../client/index.html'
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
				response.status = 404
				response.content_type 'text/plain'
				response.content = 'Not Found'
			end

			response.send_response
		end
	end

	# Start the HTTP server
	EM.start_server "0.0.0.0", http_port, HttpServer
	puts "HTTP server started on http://0.0.0.0:#{http_port}"
end
