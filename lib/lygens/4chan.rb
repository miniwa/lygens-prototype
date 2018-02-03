# Holds code for the HTTP client and related things
require "rest-client"

module Lygens
    module FourChan
        class Client
            def initialize(host = nil)
                if host.nil?
                    @host = "http://a.4cdn.org"
                else
                    @host = host
                end
            end
    
            def make_request(method, url, headers = {}, params = {}, payload = {})
                args = {
                    method: method,
                    url: @host + url
                }

                if !headers.empty?
                    args[:headers] = headers
                end

                
                RestClient::Request.execute(method: method, )
            end
        end
    end
end
