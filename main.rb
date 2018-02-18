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
captcha_client = Lyg::AntiCaptchaClient.new(transport,
    captcha_api_key)

# Create poster
pool = Concurrent::ThreadPoolExecutor.new(min_threads: 5,
    max_threads: 20, max_queue: 0)
poster = Lyg::LygensPoster.new(client, captcha_client, pool)
poster.source_boards.push("pol")

# Payload
board = "v"
thread_number = "407240385"

times = 50
1.upto(times) do |i|
    logger.debug("Post#{i}")
    begin
        promise = poster.shitpost(board, thread_number)

        logger.debug("Awaiting post promise..")
        promise.execute().value
        if promise.fulfilled?
            logger.debug("Promise completed. Sleeping..")
        elsif promise.rejected?
            logger.debug("Promise failed: ")
            raise promise.reason
        end
        sleep(40)
    rescue Lyg::FourChanPostError => exc
        logger.debug("Post rejected. (#{exc})")
        exit(1)
    end
end
