module Lyg
    # Maintains a list of four chan clients to use when accessing the api
    class LygensClientPool
        def initialize(proxy_client, captcha_client)
            @proxy_client = proxy_client
            @captcha_client = captcha_client
            @clients = []
        end

        def get_valid_client
        end

        def fetch_new_client
            proxy = @proxy_client.get_proxy
        end

        def client_valid?(client, captcha)
            return client.get_ban_status
        end
    end
end
