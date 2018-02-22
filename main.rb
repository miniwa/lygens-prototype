require "bundler/setup"
require "lygens"
require "logging"
require "json"
require "concurrent"

# Config
Logging.logger.root.level = :debug
Logging.logger.root.appenders = Logging.appenders.stdout
logger = Logging.logger["main"]
captcha_api_key = "11346f1d5172530024ab2dc6ea6dbe05"
proxy_filename = "proxies.txt"

# Clients
transport = Lyg::RestClientHttpTransport.new
client = Lyg::FourChanClient.new(transport)
captcha_client = Lyg::AntiCaptchaClient.new(transport,
    captcha_api_key)
solver = Lyg::LygensCaptchaSolver.new(captcha_client)

# Thread pool
pool = Concurrent::ThreadPoolExecutor.new(min_threads: 5, max_queue: 0)

# Proxy
lines = File.read(proxy_filename)
proxies = Lyg::Util.parse_proxy_lines(lines)
logger.debug("Parsed #{proxies.length} proxies from #{proxy_filename}")

#logger.debug("Removing dead proxies..")
alive = Lyg::Util.remove_dead_proxies(proxies, pool)
logger.debug("#{alive.length} alive proxies remaining")

#proxy_client = Lyg::GimmeProxyClient.new(transport)
proxy_client = Lyg::ProxyListClient.new(proxies.shuffle)

# Create poster
poster = Lyg::LygensPoster.new(transport, client,
    solver, proxy_client, pool)
poster.source_boards.push("pol")

# Payload
board = "v"
thread_number = "407563804"

# Locals
desired_clients = 5
client_promises = []
post_promises = [poster.shitpost(board, thread_number).execute]
#post_promises = []

while true
    begin
        # Schedule new clients
        if poster.client_pool.length < desired_clients
            should_add = desired_clients - poster.client_pool.length -
                client_promises.length
            1.upto(should_add) do
                client_promises.push(poster.fetch_new_client_async.execute)
            end

            if should_add > 0
                logger.debug("Scheduled #{should_add} new clients to be fetched")
            end
        end

        # Check previously scheduled clients
        client_promises.each do |promise|
            if promise.fulfilled?
                logger.debug("Client fetched and added to poster client list")
                poster.client_pool.add(promise.value)
            elsif promise.rejected?
                reason = promise.reason
                logger.warn("Fetch client promise failed: (#{reason.class}:"\
                " #{reason.message}) #{reason.backtrace}")
            end
        end

        client_promises.delete_if do |promise|
            promise.rejected? || promise.fulfilled?
        end

        post_promises.each do |promise|
            if promise.fulfilled?
                logger.debug("Post promise completed. Scheduling one more")
                post_promises
                    .push(poster.shitpost(board, thread_number).execute)
            elsif promise.rejected?
                logger.debug("Post promise failed: ")
                raise promise.reason
            end
        end
        post_promises.delete_if do |promise|
            promise.rejected? || promise.fulfilled?
        end

        sleep(0.02)
    rescue Lyg::FourChanPostError => exc
        logger.debug("Post rejected. (#{exc.message}) #{exc.backtrace.inspect}")
        exit(1)
    rescue StandardError => exc
        logger.warn("Something fucked up: (#{exc.class}: #{exc.message})"\
        " #{exc.backtrace.inspect}")
        raise exc
    end
end
