require "lygens/four_chan/comment"
require "lygens/four_chan/client"
require "lygens/client_pool"
require "logging"
require "concurrent"

module Lyg
    # An concurrent wrapper for executing actions on four chan objects
    class LygensPoster
        def initialize(transport, client, solver, proxy_client, executor)
            @transport = transport
            @client = client
            @solver = solver

            @proxy_client = proxy_client
            @executor = executor

            @source_boards = Concurrent::Array.new
            @client_pool = LygensClientPool.new(60)
            @logger = Logging.logger[self]
        end

        def shitpost(board, thread_number)
            thread_promise = @client.get_thread_async(board, thread_number,
                @executor).execute
            answer_promise = @solver.get_answer_async(@executor).execute
            reply_promise = get_random_reply_async.execute

            return Concurrent::Promise.zip(thread_promise, answer_promise,
                reply_promise)
                .then(executor: @executor) do |result|
                thread = result[0]
                answer = result[1]
                reply = result[2]

                @logger.debug("Fetching target..")
                target = get_target_post(thread)
                @logger.debug("Post with id: #{target.number} is the target")
                comment = FourChanComment.replace_quotes(reply.comment,
                    target.number)
                @logger.debug("Final reply: \n\"\"\"\n#{comment}\n\"\"\"")

                post_client = wait_for_client
                @logger.debug("Using four chan client with proxy:"\
                    " #{post_client.proxy}")
                @logger.debug("Attempting to post..")

                begin
                    @client_pool.set_timestamp(post_client, Time.now)
                    post_client.post(board, thread.op.number, comment, answer)
                rescue FourChanBannedError, FourChanCaptchaError,
                    FourChanHttpError, FourChanTimeoutError => exc
                    if exc.is_a?(FourChanBannedError)
                        @logger.debug("Comment rejected because of IP ban")
                        @client_pool.remove(post_client)
                        post_client = wait_for_client
                        answer = @solver.get_answer
                    elsif exc.is_a?(FourChanCaptchaError)
                        @logger.debug("Captcha reported as false")
                        answer = @solver.get_answer
                    elsif exc.is_a?(FourChanTimeoutError)
                        @logger.debug("This ip is timed out")
                        post_client = wait_for_client
                        answer = @solver.get_answer
                    else
                        @logger.debug("Http error when trying to post")
                        @client_pool.remove(post_client)
                        post_client = wait_for_client
                    end

                    retry
                end

                @logger.debug("Sucessfully posted comment")
            end
        end

        def fetch_new_client
            client = FourChanClient.new(@transport)
            while true
                begin
                    @logger.debug("Fetching new proxy..")
                    proxy = @proxy_client.get_proxy
                    @logger.debug("New proxy at at: #{proxy.uri}")
                    client.proxy = proxy.uri
                    client.post("v", 1, "hi", "token")
                rescue FourChanCaptchaError
                    @logger.debug("Passed sanity check")
                rescue FourChanHttpError, FourChanPostError
                    @logger.debug("Proxy test reports error, trying another..")
                    retry
                end

                answer = @solver.get_answer
                begin

                    @logger.debug("Checking proxy ban status..")
                    unless client.get_ban_status(answer)
                        @logger.debug("Proxy is whitelisted")
                        return client
                    end
                    @logger.debug("Proxy is banned.")
                rescue FourChanCaptchaError
                    @logger.debug("Invalid captcha reported when checking ban")
                    answer = @solver.get_answer
                    retry
                rescue FourChanHttpError, FourChanPostError
                end
            end
        end

        def fetch_new_client_async
            return Concurrent::Promise.new(executor: @executor) do
                fetch_new_client
            end
        end

        def wait_for_client
            while true
                client = @client_pool.get_cool_client
                unless client.nil?
                    @client_pool.set_timestamp(client, Time.now + 60)
                    return client
                end
                sleep 0.1
            end
        end

        def wait_for_client_async
            return Concurrent::Promise.new(executor: @executor) do
                wait_for_client
            end
        end

        def get_random_reply
            begin
                source = @source_boards.sample
                thread_numbers = @client.get_thread_numbers(source)

                @logger.debug("Shuffling thread numbers")
                thread_numbers.shuffle.each do |thread_number|
                    thread = @client.get_thread(source, thread_number.number)

                    @logger.debug("Shuffling post numbers")
                    thread.replies.shuffle.each do |reply|
                        if FourChanComment.has_quote(reply.comment) &&
                            reply.comment.split(" ").length > 10
                            @logger.debug("Matching reply found")
                            return reply
                        end
                    end
                end
            rescue StandardError => exc
                @logger.warn("Unhandled exception when getting reply"\
                "(#{exc.class} #{exc.message}) #{exc.backtrace}")
                raise exc
            end

            raise FourChanError, "No post matched the given criterias"
        end

        # Returns a promise that will eventually yield a weighted random reply
        # from one of the configured source boards
        def get_random_reply_async
            return Concurrent::Promise.new(executor: @executor) do
                get_random_reply
           end
        end

        def get_random_thread(board)
            thread_numbers = @client.get_threads(board)
            return @client.get_thread(board, thread_numbers.sample().number)
        end

        # Returns a weighted random target post in given thread
        def get_target_post(thread)
            if thread.replies.any?
                len = thread.replies.length
                if len > 20
                    return thread.replies[len - 20, len].sample
                else
                    return thread.replies.sample
                end
            else
                return thread.op
            end
        end

        attr_accessor :posts_made, :source_boards, :client_pool
    end
end
