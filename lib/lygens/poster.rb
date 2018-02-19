require "lygens/four_chan/comment"
require "lygens/four_chan/client"
require "logging"
require "concurrent"

module Lyg
    # An concurrent wrapper for executing actions on four chan objects
    class LygensPoster
        def initialize(transport, client, captcha_client,
                proxy_client, executor)
            @transport = transport
            @client = client
            @captcha_client = captcha_client
            @site = "https://boards.4chan.org/v"
            @site_key = "6Ldp2bsSAAAAAAJ5uyx_lx34lJeEpTLVkP5k04qc"
            @proxy_client = proxy_client
            @executor = executor

            @posts_made = {}
            @source_boards = []
            @logger = Logging.logger[self]
        end

        def shitpost(board, thread_number)
            thread_promise = @client.get_thread_async(board, thread_number,
                @executor)
            captcha_promise = get_captcha_async.execute
            reply_promise = get_random_reply_async.execute
            proxy_promise = get_valid_proxy_async(5).execute

            return Concurrent::Promise.zip(thread_promise,
                captcha_promise, reply_promise, proxy_promise)
                .then(executor: @executor) do |result|
                thread = result[0]
                answer = result[1]
                reply = result[2]
                proxy = result[3]

                target = get_target_post(thread)
                @logger.debug("Post with id: #{target.number} is the target")
                comment = FourChanComment.replace_quotes(reply.comment,
                    target.number)
                @logger.debug("Final reply: \n\"\"\"\n#{comment}\n\"\"\"")

                post_client = FourChanClient.new(@transport)
                post_client.proxy = proxy.uri
                @logger.debug("Creating four chan client with proxy:"\
                    " #{proxy.uri}")

                @logger.debug("Attempting to post..")
                post_tries = 0
                begin
                    post_client.post(board, thread.op.number, comment, answer)
                rescue FourChanBannedError, FourChanCaptchaError => exc
                    if exc.is_a?(FourChanBannedError)
                        @logger.debug("Commented rejected because of IP ban")
                    elsif exc.is_a?(FourChanCaptchaError)
                        @logger.debug("Captcha reported as false")
                    end

                    @logger.debug("Fetching new captcha")
                    answer_promise = get_captcha_async.execute
                    if exc.is_a?(FourChanBannedError)
                        @logger.debug("Switching proxy..")
                        post_client.proxy = get_valid_proxy(5).uri
                        @logger.debug("New proxy: #{post_client.proxy}")
                    end
                    answer = answer_promise.value
                    if answer_promise.rejected?
                        raise answer_promise.reason
                    end
                rescue FourChanHttpError => exc
                    @logger.debug("HTTP error when trying to post")
                    @logger.debug("Switching proxy..")
                    post_client.proxy = get_valid_proxy(5).uri

                    @logger.debug("New proxy: #{post_client.proxy}")
                    retry
                rescue FourChanCaptchaError => exc
                    @logger.debug("Captcha was not valid. Fetching new one..")
                    answer = get_captcha_async.execute.val
                rescue FourChanArchivedError => exc
                    raise exc
                rescue FourChanPostError => exc
                    post_tries += 1
                    if post_tries < 6
                        @logger.debug("Comment rejected. Retrying in 5..")
                        sleep(5)
                        retry
                    else
                        raise FourChanPostError, "Could not post message"
                    end
                end
                @logger.debug("Sucessfully posted comment")
            end
        end

        def get_captcha_async
            return Concurrent::Promise.new(executor: @executor) do
                @logger.debug("Creating recaptcha task..")
                task_id = @captcha_client.create_recaptcha_task(@site, @site_key)
                @logger.debug("Task #{task_id} created.")
                sleep(5)

                tries = 0
                answer = nil
                while tries < 25
                    tries += 1
                    @logger.debug("Fetching status of captcha task..")
                    response = @captcha_client.get_recaptcha_result(task_id)
                    if response.is_ready
                        @logger.debug("Answer ready: #{response.answer}")
                        answer = response.answer
                        break
                    end

                    @logger.debug("Captcha task pending. Sleeping 5 seconds..")
                    sleep(5)
                end

                if !answer.nil?
                    answer
                else
                    raise StandardError, "Captcha task timed out"
                end
            end
        end

        def get_valid_proxy(timeout)
            test_client = FourChanClient.new(@transport)
            test_client.timeout = timeout
            begin
                @logger.debug("Retrieving new proxy from api")
                proxy = @proxy_client.get_proxy
                @logger.debug("Proxy fetched: #{proxy.uri}")

                @logger.debug("Checking proxy sanity..")
                test_client.proxy = proxy.uri
                test_client.post("v", 1, "hi", "token")
            rescue FourChanCaptchaError
                @logger.debug("Passed check")
                return proxy
            rescue FourChanHttpError
                @logger.debug("Test reports HTTP error. Trying another..")
                retry
            rescue FourChanPostError
                @logger.debug("Tests report 4chan-related"\
                " error. Trying another..")
                retry
            rescue StandardError => exc
                @logger.debug("Caught weird #{exc.class}. (#{exc.message}"\
                    " #{exc.backtrace.inspect})")
                raise exc
            end
        end

        def get_valid_proxy_async(timeout)
            return Concurrent::Promise.new(executor: @executor) do
                get_valid_proxy(timeout)
            end
        end

        # Returns a promise that will eventually yield a weighted random reply
        # from one of the configured source boards
        def get_random_reply_async
            return Concurrent::Promise.new(executor: @executor) do
                source = @source_boards.sample
                thread_numbers = @client.get_thread_numbers(source)
                result = nil

                thread_numbers.shuffle.each do |thread_number|
                    thread = @client.get_thread(source, thread_number.number)
                    thread.replies.shuffle.each do |reply|
                        if FourChanComment.has_quote(reply.comment) &&
                            reply.comment.split(" ").length > 10
                            result = reply
                            @logger.debug("Matching reply found")
                            break
                        end
                    end

                    unless result.nil?
                        break
                    end
                end

                if !result.nil?
                    result
                else
                    raise FourChanError, "No post matched the given criterias"
                end
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

        attr_accessor :posts_made, :source_boards
    end
end
