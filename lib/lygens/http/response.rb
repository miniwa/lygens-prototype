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
            @content = nil

            super()
        end

        # Returns the content of this response as an instance of given object
        # type. Raises ParserError or ArgumentError on failure.
        def parse_as(class_type)
            if @content.nil?
                raise ArgumentError, "Response does not contain content"
            end

            if @parser.nil?
                raise ArgumentError, "Response does not have a parser assigned"
            end

            return @parser.parse_as(class_type, @content)
        end

        # The HTTP status code of the response
        def code
            return @code
        end

        # Returns the content of the the response, or nil if no content was
        # included
        def content
            return @content
        end

        # Assigns the content of the response
        def content=(content)
            @content = content
        end

        attr_accessor :parser
    end
end
