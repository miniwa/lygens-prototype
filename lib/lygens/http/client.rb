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
            end
        end
    end
end
