require 'json'

module Timer
	@callbacks = []
	@running = false
	@thread = nil

	class << self
		def add_hook(&hook)
			@callbacks.push(hook)
		end

		def remove_hook(&hook)
			@callbacks.delete(hook)
		end

		def run(interval)
			if @running then
				return
			end

			@running = true

			@thread = Thread.new do
				target_interval = 1.0 / interval
				last_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
				sleep_time = target_interval

				while @running

					@callbacks.each do |callback|
						callback.call
					end

					now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
					actual_interval = now - last_time
					last_time = now

					drift = actual_interval - target_interval
					sleep_time -= drift

					sleep(sleep_time) if sleep_time > 0
				end
			end
		end

		def stop()
			@running = false
			thread.join
		end
	end
end
