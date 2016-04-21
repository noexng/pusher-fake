if Pusher.app_id.nil?
  warn <<-EOS.strip
    Warning: `Pusher.app_id` is not set. Should be set before including PusherFake."
  EOS
end

if Pusher.key.nil?
  warn <<-EOS.strip
    Warning: `Pusher.key` is not set. Should be set before including PusherFake.
  EOS
end

if Pusher.secret.nil?
  warn <<-EOS.strip
    Warning: `Pusher.secret` is not set. Should be set before including PusherFake.
  EOS
end

# Use the same API key and secret as the live version.
PusherFake.configure do |configuration|
  configuration.app_id = Pusher.app_id
  configuration.key    = Pusher.key
  configuration.secret = Pusher.secret
end

# Set the host and port to the fake web server.
PusherFake.configuration.web_options.tap do |options|
  Pusher.host = options[:host]
  Pusher.port = options[:port]
end

# Start the fake socket and web servers.
fork { PusherFake::Server.start }.tap do |id|
  at_exit { Process.kill("KILL", id) }
end
