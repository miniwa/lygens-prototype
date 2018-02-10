require "lygens/http/message"

module Lyg
    # Represents a HTTP response
    class HttpResponse < HttpMessage
        # A list of valid HTPP status codes
        VALID_CODES = (100..103).to_a + (200..208).to_a + [226] +
            (300..308).to_a + (400..418).to_a + (421..424).to_a +
            [426, 428, 429, 431, 451] + (500..511).to_a

        # Creates a new response with given status code
        def initialize(code)
            unless VALID_CODES.include?(code)
                raise ArgumentError, "Invalid HTTP status code"
            end
            @code = code
            @body = nil

            super()
        end

        # The HTTP status code of the response
        def code
            return @code
        end

        # Returns the body of the the response, or nil if no body was
        # included
        def body
            return @body
        end

        # Assigns the body of the response
        def body=(body)
            @body = body
        end
    end
end
