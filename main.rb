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
pool = Concurrent::ThreadPoolExecutor.new(min_threads: 5,
    max_threads: 300, max_queue: 0)

# Proxy
lines = File.read(proxy_filename)
proxies = Lyg::Util.parse_proxy_lines(lines).shuffle
logger.debug("Parsed #{proxies.length} proxies from #{proxy_filename}")

proxy_client = Lyg::GimmeProxyClient.new(transport)
#proxy_client = Lyg::ProxyListClient.new(proxies.shuffle)

# Create poster
poster = Lyg::LygensPoster.new(transport, client,
    solver, proxy_client, pool)
poster.source_boards.push("pol")

# Payload
board = "v"
thread_number = "407690309"

# Locals
unchecked = Concurrent::Array.new
promises = Concurrent::Array.new
max_requests = 150
captcha_count = 0
responsive = Concurrent::Array.new
#post_promises = [poster.shitpost(board, thread_number).execute]
post_promises = []
unchecked += proxies

while true
    begin
        if responsive.any?
            available = responsive.length
            space = max_requests - promises.length
            if available > space
                count = space
            else
                count = available
            end

            1.upto(count) do |index|
                client = responsive.pop
                promise = solver.get_answer_async(pool).then do |answer|
                    begin
                        logger.debug("Checking ban status of client..")
                        client.get_ban_status(answer)
                    rescue Lyg::FourChanError
                        true
                    end
                end

                promise = promise.then do |banned|
                    if !banned
                        logger.info("Not banned. Adding to clients..")
                        poster.clients.add(client)
                    else
                        logger.debug("Client is banned")
                    end
                end
                promises.push(promise.execute)
            end
        end

        if unchecked.any?
            available = unchecked.length
            space = max_requests - promises.length
            if available > space
                count = space
            else
                count = available
            end

            1.upto(count) do |index|
                proxy = unchecked.pop
                client = Lyg::FourChanClient.new(transport)
                client.proxy = proxy.uri
                client.timeout = 5

                promise = Lyg::Util.is_client_responsive_async(client, pool).then do |value|
                    if value
                        responsive.push(client)
                    end
                end
                promises.push(promise.execute)
            end
        end
        promises.each do |promise|
            if promise.rejected?
                raise promise.reason
            end
        end
        promises.delete_if do |promise|
            promise.complete?
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
