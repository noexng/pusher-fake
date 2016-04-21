module PusherFake
  module Server
    # The application for the web server.
    class Application
      CHANNEL_FILTER_ERROR = %(
        user_count may only be requested for presence channels -
        please supply filter_by_prefix begining with presence-
      ).freeze

      CHANNEL_USER_COUNT_ERROR = %(
        Cannot retrieve the user count unless the channel is a presence channel
      ).freeze

      PRESENCE_PREFIX_MATCHER = /\Apresence-/

      # Process an API request.
      #
      # @param [Hash] environment The request environment.
      # @return [Rack::Response] A successful response.
      def self.call(environment)
        id       = PusherFake.configuration.app_id
        request  = Rack::Request.new(environment)
        response = route(id, request) || raise("Unknown path: #{request.path}")

        Rack::Response.new(MultiJson.dump(response)).finish
      rescue => error
        Rack::Response.new(error.message, 400).finish
      end

      def self.route(id, request)
        case request.path
        when %r{\A/apps/#{id}/events\Z}
          events(request)
        when %r{\A/apps/#{id}/channels\Z}
          channels(request)
        when %r{\A/apps/#{id}/channels/([^/]+)\Z}
          channel(Regexp.last_match[1], request)
        when %r{\A/apps/#{id}/channels/([^/]+)/users\Z}
          users(Regexp.last_match[1])
        end
      end

      # Emit an event with data to the requested channel(s).
      #
      # @param [Rack::Request] request The HTTP request.
      # @return [Hash] An empty hash.
      def self.events(request)
        event = MultiJson.load(request.body.read)
        data  = begin
                  MultiJson.load(event["data"])
                rescue MultiJson::LoadError
                  event["data"]
                end

        event["channels"].each do |channel_name|
          channel = Channel.factory(channel_name)
          channel.emit(event["name"], data, socket_id: event["socket_id"])
        end

        {}
      end

      # Return a hash of channel information.
      #
      # Occupied status is always included. A user count may be requested for
      # presence channels.
      #
      # @param [String] name The channel name.
      # @param [Rack::Request] request The HTTP request.
      # @return [Hash] A hash of channel information.
      def self.channel(name, request)
        info = request.params["info"].to_s.split(",")

        if info.include?("user_count") && name !~ PRESENCE_PREFIX_MATCHER
          raise CHANNEL_USER_COUNT_ERROR
        end

        channels = PusherFake::Channel.channels || {}
        channel  = channels[name]

        {}.tap do |result|
          result[:occupied] = !channel.nil? && channel.connections.length > 0

          if channel && info.include?("user_count")
            result[:user_count] = channel.connections.length
          end
        end
      end

      # Returns a hash of occupied channels, optionally filtering with a
      # prefix.
      #
      # When filtering to presence chanenls, the user count maybe also be
      # requested.
      #
      # @param [Rack::Request] request The HTTP request.
      # @return [Hash] A hash of occupied channels.
      def self.channels(request)
        info   = request.params["info"].to_s.split(",")
        prefix = request.params["filter_by_prefix"].to_s

        if info.include?("user_count") && prefix !~ PRESENCE_PREFIX_MATCHER
          raise CHANNEL_FILTER_ERROR
        end

        filter   = Regexp.new(/\A#{prefix}/)
        channels = PusherFake::Channel.channels || {}
        channels.each_with_object(channels: {}) do |result, (name, channel)|
          unless filter && name !~ filter
            channels = result[:channels]
            channels[name] = {}

            if info.include?("user_count")
              channels[name][:user_count] = channel.connections.length
            end
          end

          result
        end
      end

      # Returns a hash of the IDs for the users in the channel.
      #
      # @param [String] name The channel name.
      # @return [Hash] A hash of user IDs.
      def self.users(name)
        channels = PusherFake::Channel.channels || {}
        channel  = channels[name]

        if channel
          users = channel.connections.map do |connection|
            { id: connection.id }
          end
        end

        { users: users || [] }
      end
    end
  end
end
