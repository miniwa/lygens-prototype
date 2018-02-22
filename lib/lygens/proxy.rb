module Lyg
    class ProxyListClient
        def initialize(proxies)
            @proxies = proxies
            @index = 0
            @lock = Concurrent::ReadWriteLock.new
        end
        
        def get_proxy
            proxy = nil
            @lock.with_write_lock do
                proxy = @proxies[@index]
                @index += 1
            end

            return proxy
        end
    end
end
