module PusherFake
  # A client connection.
  class Connection
    # Name matcher for client events.
    CLIENT_EVENT_MATCHER = /\Aclient-(.+)\Z/

    # @return [EventMachine::WebSocket::Connection] The socket object.
    attr_reader :socket

    # Create a new {Connection} object.
    #
    # @param [EventMachine::WebSocket::Connection] socket The socket object.
    def initialize(socket)
      @socket = socket
    end

    # The ID of the connection.
    #
    # @return [Integer] The object ID of the socket.
    def id
      parts = socket.object_id.to_s.split("")
      parts = parts.each_slice(parts.length / 2).to_a

      [parts.first.join(""), parts.last.join("")].join(".")
    end

    # Emit an event to the connection.
    #
    # @param [String] event The event name.
    # @param [Hash] data The event data.
    # @param [String] channel The channel name.
    def emit(event, data = {}, channel = nil)
      message = { event: event, data: MultiJson.dump(data) }
      message[:channel] = channel if channel

      PusherFake.log("SEND #{id}: #{message}")

      socket.send(MultiJson.dump(message))
    end

    # Notify the Pusher client that a connection has been established.
    def establish
      emit("pusher:connection_established",
           socket_id: id, activity_timeout: 120)
    end

    # Process an event.
    #
    # @param [String] data The event data as JSON.
    def process(data)
      message = MultiJson.load(data, symbolize_keys: true)

      PusherFake.log("RECV #{id}: #{message}")

      data    = message[:data]
      event   = message[:event]
      name    = message[:channel] || data[:channel]
      channel = Channel.factory(name) if name

      case event
      when "pusher:subscribe"
        channel.add(self, data)
      when "pusher:unsubscribe"
        channel.remove(self)
      when "pusher:ping"
        emit("pusher:pong")
      when CLIENT_EVENT_MATCHER
        if channel.is_a?(Channel::Private) && channel.includes?(self)
          channel.emit(event, data, socket_id: id)

          trigger(channel, id, event, data)
        end
      end
    end

    private

    def trigger(channel, id, event, data)
      Thread.new do
        hook = { event: event, channel: channel.name, socket_id: id }
        hook[:data] = MultiJson.dump(data) if data

        if channel.is_a?(Channel::Presence)
          hook[:user_id] = channel.members[self][:user_id]
        end

        channel.trigger("client_event", hook)
      end
    end
  end
end
