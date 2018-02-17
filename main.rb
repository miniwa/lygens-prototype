require "bundler/setup"
require "lygens"
require "logging"
require "json"

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
poster = Lyg::LygensPoster.new(client, captcha_client)

# Payload
board = "v"
thread_number = "407127636"

times = 50
1.upto(times) do |i|
    logger.debug("Post#{i}")
    begin
        poster.shitpost(board, thread_number)
        sleep(40)
    rescue FourChanPostError
        @logger.debug("Post rejected, retrying post procedure")
    end
end
