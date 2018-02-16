require "lygens"

module Lyg
    class HttpJsonContent
        def initialize(buffer = nil)
            @buffer = buffer
        end

        def as_text
            return JSON.generate(@buffer)
        end

        def get_headers
            return {
                "Content-Type" => "	application/json"
            }
        end

        attr_accessor :buffer
    end

    class HttpMultiPartContent
        def initialize
            @parts = {}
        end

        def as_text
            raise NotImplementedError, "as_text is not implemented"
        end

        def get_headers
            raise NotImplementedError, "get_headers is not implemented"
        end

        attr_accessor :parts
    end
end
