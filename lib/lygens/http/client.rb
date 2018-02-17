# Holds code for the HTTP client and related things
require "concurrent"
require "rest-client"

module Lyg
    # Represents a thread-safe abstraction over http that acts more like a
    # browser than an api.
    class HttpClient
        # Initializes the +HttpClient+ with a given +HttpTransport+
        def initialize(transport)
            @transport = transport
            @headers = Concurrent::Hash.new
            @cookies = Concurrent::Hash.new
            @autosave_cookies = false
        end

        # Returns the preset headers of the client
        def headers
            return @headers
        end

        # Returns the preset cookies of the client
        def cookies
            return @cookies
        end

        # Executes a given +HttpRequest+ with the preset headers and cookies
        # added to it.
        def execute(request)
            @headers.each do |key, value|
                unless request.headers.key?(key)
                    request.headers[key] = value
                end
            end

            @cookies.each do |key, value|
                unless request.cookies.key?(key)
                    request.cookies[key] = value
                end
            end

            begin
                response = @transport.execute(request)
            rescue SocketError => exc
                raise HttpConnectionError, "Request could not be executed"\
                " (#{exc})"
            end

            if @autosave_cookies
                response.cookies.each do |key, value|
                    cookies[key] = value
                end
            end

            return response
        end

        attr_accessor :autosave_cookies
    end
end
