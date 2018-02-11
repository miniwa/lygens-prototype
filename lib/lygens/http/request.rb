require "lygens/http/message"

module Lyg
    # Represents an HTTP request
    class HttpRequest < HttpMessage
        METHODS = [:get, :post, :put, :head, :delete, :options, :connect]
        def initialize(method, url)
            unless METHODS.include?(method)
                raise ArgumentError, "Invalid HTTP method"
            end

            if url.nil?
                raise ArgumentError, "Url is required"
            end
            
            @method = method
            @url = url
            @parameters = {}
            super()
        end

        # Returns the method of the request
        def method
            return @method
        end

        # Returns the url of the request
        def url
            return @url
        end

        # Returns a hash containing the query parameters of the request
        def parameters
            return @parameters
        end
    end
end
