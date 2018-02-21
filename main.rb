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

# Clients
transport = Lyg::RestClientHttpTransport.new
client = Lyg::FourChanClient.new(transport)
proxy_client = Lyg::GimmeProxyClient.new(transport)
captcha_client = Lyg::AntiCaptchaClient.new(transport,
    captcha_api_key)
solver = Lyg::LygensCaptchaSolver.new(captcha_client)

# Create poster
pool = Concurrent::ThreadPoolExecutor.new(min_threads: 5,
    max_threads: 50, max_queue: 0)
poster = Lyg::LygensPoster.new(transport, client,
    solver, proxy_client, pool)
poster.source_boards.push("pol")

# Payload
board = "v"
thread_number = "407468980"

# Locals
desired_clients = 4
client_promises = []
post_promises = [poster.shitpost(board, thread_number).execute]
#post_promises = []

while true
    begin
        # Schedule new clients
        if poster.clients.length < desired_clients
            should_add = desired_clients - poster.clients.length -
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
                poster.clients.push(promise.value)
            elsif promise.rejected?
                reason = promise.reason
                logger.warn("Fetch client promise failed: #{reason.class}"\
                " #{reason.backtrace}")
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
