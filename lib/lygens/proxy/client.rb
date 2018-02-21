require "lygens/model/parser"
require "lygens/http/client"
require "lygens/http/request"
require "lygens/model/model"
require "lygens/proxy/error"

module Lyg
    class GimmeProxyClient < HttpClient
        def initialize(transport, host = "https://gimmeproxy.com")
            @host = host
            super(transport)
        end

        # Returns a new proxy from gimme proxy. This proxy is guaranteed to
        # have been checked within the last hour, to support get and post, to
        # support HTTPS and be of type "http"
        def get_proxy
            request = HttpRequest.new(:get, "#{@host}/api/getProxy")
            request.parameters["get"] = true
            request.parameters["post"] = true
            request.parameters["supportsHttps"] = true
            request.parameters["protocol"] = "http"
            request.parameters["maxCheckPeriod"] = (60 * 60)

            response = execute(request)
            if response.code != 200
                raise GimmeProxyError, "GimmeProxy server replied with code:"\
                "#{response.code}"
            end
            response.parser = JsonParser.new

            dto = response.parse_as(GetProxyDto)
            return parse_proxy(dto)
        end

        # Returns a promise that will eventually yield a new proxy from
        # gimme proxy.
        def get_proxy_async(executor)
            return Concurrent::Promise.new(executor: executor) do
                get_proxy
            end
        end

        def parse_proxy(dto)
            proxy = HttpProxy.new
            proxy.ip = dto.ip
            proxy.port = dto.port.to_i
            proxy.country = dto.country
            proxy.supports_https = dto.supports_https
            proxy.anonymous = dto.anonymity_level == 1

            return proxy
        end
    end

    GetProxyDto = Model.define do
        field :supports_https do
            key "supportsHttps"
        end

        field :protocol
        field :ip
        field :port
        field :country
        field :anonymity_level do
            key "anonymityLevel"
        end
    end
end
