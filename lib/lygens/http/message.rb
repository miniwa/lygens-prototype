module Lyg
    # Baseclass for http messages
    class HttpMessage

        def initialize
            @cookies = {}
            @headers = {}
        end

        # Returns the cookies of the message as a hash
        def cookies
            return @cookies
        end

        # Returns the headers of the message as a hash
        def headers
            return @headers
        end
    end
end
