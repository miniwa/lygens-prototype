require "lygens/four_chan/comment"
require "lygens/four_chan/client"
require "logging"
require "concurrent"

module Lyg
    # An concurrent wrapper for executing actions on four chan objects
    class LygensPoster
        def initialize(client, captcha_client, executor)
            @client = client
            @captcha_client = captcha_client
            @site = "https://boards.4chan.org/v"
            @site_key = "6Ldp2bsSAAAAAAJ5uyx_lx34lJeEpTLVkP5k04qc"
            @posts_made = {}
            @source_boards = []
            @logger = Logging.logger[self]
            @executor = executor
        end

        def shitpost(board, thread_number)
            thread_promise = @client.get_thread_async(board, thread_number,
                @executor).execute
            captcha_promise = get_captcha_async.execute
            reply_promise = get_random_reply_async.execute

            return Concurrent::Promise.zip(thread_promise,
                captcha_promise, reply_promise)
                .then(executor: @executor) do |result|
                thread = result[0]
                answer = result[1]
                reply = result[2]

                target = get_target_post(thread)
                comment = FourChanComment.replace_quotes(reply.comment,
                    target.number)
                @logger.debug("Got reply {#{comment}}.")

                @logger.debug("Attempting to post..")
                post_tries = 0
                begin
                    @client.post(board, thread.op.number, comment, answer)
                rescue FourChanBannedError => exc
                    raise exc
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
                    @logger.debug("Fetching status of task..")
                    response = @captcha_client.get_recaptcha_result(task_id)
                    @logger.debug("Task status fetched")
                    if response.is_ready
                        @logger.debug("Answer ready: #{response.answer}")
                        answer = response.answer
                        break
                    end

                    @logger.debug("Task pending. Sleeping 5 seconds..")
                    sleep(5)
                end

                if !answer.nil?
                    answer
                else
                    raise StandardError, "Captcha task timed out"
                end
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
