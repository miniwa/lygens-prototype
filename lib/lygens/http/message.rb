module Lyg
    # Baseclass for http messages
    class HttpMessage
        def initialize
            @cookies = {}
            @headers = {}
            @content = nil
        end

        # Returns the cookies of the message as a hash
        def cookies
            return @cookies
        end

        # Returns the content of the the message, or nil if no content was
        # included
        def content
            return @content
        end

        # Assigns the content of the message
        def content=(content)
            @content = content
        end

        # Returns the headers of the message as a hash
        def headers
            return @headers
        end
    end
end
