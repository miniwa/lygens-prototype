# Holds code for the HTTP client and related things
require "concurrent"
require "rest-client"

module Lygens
    module Http
        # Represents a thread-safe abstraction over http that acts more like a
        # browser than an api.
        class Client
            # Initializes the +Client+ with a given +Transport+
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

            # Makes a http request with the given parameters. The hash may
            # contain the following values:
            # * +url+ - The url to make the request to.
            # * +method+ - The method to use when making the request.
            # * +headers+ - A hash containing a set of headers.
            # * +params+ - A hash containing a set of query parameters.
            # * +payload+ - A hash containing a set of payloads.
            def make_request(params)
                unless params.key?(:url) && params.key?(:method)
                    raise ArgumentError, "Method and url are required"
                end

                actual = params.clone
                actual[:headers] =  if params.key?(:headers)
                                        @headers.merge(params[:headers])
                                    else
                                        @headers.clone
                                    end
                actual[:cookies] =  if params.key?(:cookies)
                                        @cookies.merge(params[:cookies])
                                    else
                                        @cookies.clone
                                    end
                response = @transport.make_request(actual)

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
end
