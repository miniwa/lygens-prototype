require "lygens/http/client"
require "lygens/http/transport"
require "lygens/http/response"
require "rest-client"
require "json"

module Lygens
    module FourChan
        # Represents a client for 4chan.org.
        class Client < Http::Client
            def initialize(host = "http://a.4cdn.org")
                @host = host
                super(Http::RestClientTransport.new)
            end

            def get_thread(board, thread_no)
                url = @host + "/#{board}/thread/#{thread_no}.json"
                resp = make_request(url: url, method: :get)
                json = JSON.parse(resp.body)
                puts(json)
            end
        end
    end
end
