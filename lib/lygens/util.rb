require "lygens/http/client"
require "socket"
require "logging"

module Lyg
    module Util
        # Parses a list of proxy in the format <ip>:<port>, one per line.
        def self.parse_proxy_lines(lines)
            proxies = []
            proxy_reg = /(\d+\.\d+\.\d+\.\d+):(\d+)/
            lines.split("\n").each do |line|
                match = proxy_reg.match(line)
                if match
                    proxy = HttpProxy.new
                    proxy.ip = match[1]
                    proxy.port = match[2].to_i
                    proxy.anonymous = false
                    proxy.supports_https = false
                    proxies.push(proxy)
                end
            end

            return proxies
        end

        def self.is_client_responsive(client)
            logger = Logging.logger[self]
            begin
                client.post("v", 1, "comment", "token")
            rescue FourChanCaptchaError
                logger.debug("Passed response test")
                return true
            rescue StandardError
                return false
            end

            return false
        end

        def self.is_client_responsive_async(client, executor)
            return Concurrent::Promise.new(executor: executor) do
                is_client_responsive(client)
            end
        end
    end
end
