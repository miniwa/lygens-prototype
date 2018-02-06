# Holds code for the HTTP client and related things
require "rest-client"

module Lygens
    module Http
        # Represents a thread-safe abstraction over http that acts more like a
        # browser than an api.
        class Client
            # Initializes the +Client+ with a given +Transport+
            def initialize(transport)
                @transport = transport
                @headers = {}
                @cookies = {}
                @follow_redirects = false
                @autosave_cookies = false
            end

            def headers
                return @headers
            end

            def cookies
                return @cookies
            end

            def make_request(params)
                unless params.key?(:url) && params.key?(:method)
                    raise ArgumentError, "Method and url are required"
                end

                actual = params.clone
                if params.key?(:headers)
                    actual[:headers] = @headers.merge(params[:headers])
                else
                    actual[:headers] = @headers.clone
                end

                if params.key?(:cookies)
                    actual[:cookies] = @cookies.merge(params[:cookies])
                else
                    actual[:cookies] = @cookies.clone
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
