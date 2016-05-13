require 'thor'
require 'pusher-fake'

module PusherFake
  class CLI < Thor
    default_task("server")

    desc "server", "Run server"
    method_option :app_id, :type => :numeric, :required => true
    method_option :key, :type => :string, :required => true
    method_option :secret, :type => :string, :required => true
    method_option :web_host, :type => :string, :required => false
    method_option :web_port, :type => :numeric, :required => false
    method_option :socket_host, :type => :string, :required => false
    method_option :socket_port, :type => :numeric, :required => false

    def server
      PusherFake.configure do |configuration|
        configuration.app_id = options[:app_id]
        configuration.key    = options[:key]
        configuration.secret = options[:secret]
      end

      PusherFake.configuration.web_options[:host]    = options[:web_host] if options[:web_host]
      PusherFake.configuration.web_options[:port]    = options[:web_port] if options[:web_port]
      PusherFake.configuration.socket_options[:host] = options[:socket_host] if options[:socket_host]
      PusherFake.configuration.socket_options[:port] = options[:socket_port] if options[:socket_port]

      puts "Starting pusher-fake with"
      puts "  web: #{PusherFake.configuration.web_options[:host]}:#{PusherFake.configuration.web_options[:port]}"
      puts "  socket: #{PusherFake.configuration.socket_options[:host]}:#{PusherFake.configuration.socket_options[:port]}"
      puts "  app_id: #{PusherFake.configuration.app_id}"
      puts "  key: #{PusherFake.configuration.key}"
      puts "  secret: #{PusherFake.configuration.secret}"

      PusherFake::Server.start
    end

    desc "version", "Report the current pusher-fake version"
    def version
      puts "#{PusherFake::VERSION}"
    end
  end
end
