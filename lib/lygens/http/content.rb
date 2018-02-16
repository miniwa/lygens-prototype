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
end
