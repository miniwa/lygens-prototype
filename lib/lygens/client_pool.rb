module Lyg
    # Maintains a list of four chan clients to use when accessing the api
    class LygensClientPool
        def initialize(proxy_client, solver)
            @proxy_client = proxy_client
            @captcha_client = captcha_client
            @clients = []
        end

        def is_client_valid(client, captcha_response)
            begin
                return client.get_ban_status(captcha_response)
            rescue FourChanError
                return false
            end
        end
    end
end
