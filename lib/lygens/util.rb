require "lygens/http/client"
require "socket"

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

        def self.remove_dead_proxies(proxies, executor)
            logger = Logging.logger[self]
            promises = []
            executed = []
            alive = []

            proxies.each do |proxy|
                promises.push(is_proxy_dead_async(proxy, executor))
            end

            logger.debug("Scheduled #{promises.length} proxy checks..")
            while promises.any?
                logger.debug("#{promises.length} promises remaining..")
                executed.each do |promise|
                    if promise.fulfilled?
                        logger.debug("Proxy is alive!")
                        alive.push(promise.value)
                    elsif promise.rejected?
                        logger.debug("Proxy rejected: #{promise.reason}")
                    end
                end

                executed.delete_if do |promise|
                    promise.complete?
                end
                
                if promises.any?
                    desired = 500 - executed.length
                    1.upto(desired) do
                        unless promises.any?
                            break
                        end
                        promise = promises[0]
                        executed.push(promise.execute)
                        promises.delete(promise)
                    end
                end

                sleep 0.02
            end

            return alive
        end

        def self.is_proxy_dead(proxy)
            socket = Socket.new(
                Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
            addr = Socket.pack_sockaddr_in(proxy.port, proxy.ip)
            socket.connect(addr)

            return proxy
        end
        
        def self.is_proxy_dead_async(proxy, executor)
            return Concurrent::Promise.new(executor: executor) do
                is_proxy_dead(proxy)
            end
        end
    end
end
