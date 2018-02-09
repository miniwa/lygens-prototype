require "lygens/http/client"
require "lygens/http/transport"
require "lygens/http/response"
require "rest-client"
require "json"

module Lyg
    # Represents a client for 4chan.org.
    class FourChanClient < HttpClient
        def initialize(host = "http://a.4cdn.org")
            @host = host
            super(Http::RestClientHttpTransport.new)
        end

        def get_thread(board, number)
            url = @host + "/#{board}/thread/#{number}.json"
            resp = make_request(url: url, method: :get)
            json = JSON.parse(resp.body)
            puts(json)
        end
    end
end
