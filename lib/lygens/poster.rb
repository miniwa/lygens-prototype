require "lygens/four_chan/comment"
require "logging"

module Lyg
    class LygensPoster
        def initialize(client, captcha_client)
            @client = client
            @captcha_client = captcha_client
            @site = "https://boards.4chan.org/v"
            @site_key = "6Ldp2bsSAAAAAAJ5uyx_lx34lJeEpTLVkP5k04qc"
            @posts_made = {}
            @logger = Logging.logger[self]
        end

        def shitpost(board, thread_number)
            @logger.debug("Creating recaptcha task..")
            task_id = @captcha_client.create_recaptcha_task(@site, @site_key)
            @logger.debug("Task #{task_id} created.")

            thread = @client.get_thread(board, thread_number)
            if thread.replies.any?
                len = thread.replies.length
                if len > 20
                    target = thread.replies[len - 20, len].sample
                else
                    target = thread.replies.sample
                end
            else
                target = thread.op
            end
            
            @logger.debug("Fetching random reply..")
            match = false
            random_thread = get_random_thread("pol")
            post = random_thread.replies.sample
            filter = []
            until match
                unless random_thread.replies.any?
                    @logger.debug("Empty thread fetched. Fetching new.")
                    random_thread = get_random_thread("pol")
                    post = random_thread.replies.sample
                    next
                end

                if FourChanComment.has_quote(post.comment) &&
                    post.comment.split(" ").length > 10
                    match = true
                else
                    unless filter.include?(post.number)
                        filter.push(post.number)
                    end
                    
                    if filter.length == random_thread.replies.length
                        @logger.debug("Thread does not contain any suitable"\
                            " replies. Fetching new.")
                        filter = []
                        
                        random_thread = get_random_thread("pol")
                        until random_thread.replies.any?
                            random_thread = get_random_thread("pol")
                        end
                    else
                        @logger.debug("Comment doesn't meet standards."\
                            " Fetching a another one")
                    end
                    
                    post = random_thread.replies.sample
                    while filter.include?(post.number)
                        post = random_thread.replies.sample
                    end
                end
            end

            comment = FourChanComment.replace_quotes(post.comment,
                target.number)
            @logger.debug("Got reply {#{comment}}.")
            
            @logger.debug("Fetching status of task..")
            solved = false
            answer = nil
            tries = 0
            until solved
                tries += 1
                response = @captcha_client.get_recaptcha_result(task_id)
                if response.is_ready
                    answer = response.answer
                    solved = true
                elsif tries == 20
                    raise StandardError, "Captcha task timed out"
                end
                
                @logger.debug("Task pending. Sleeping for 5 seconds..")
                sleep(5)
            end
            @logger.debug("Captcha solved: #{answer}")
            
            @logger.debug("Attempting to post..")
            post_tries = 0
            begin
                @client.post(board, thread.op.number, comment, answer)
            rescue FourChanPostError => exc
                post_tries += 1
                if post_tries < 6
                    @logger.debug("Comment rejected. Retrying in 5..")
                    sleep(5)
                    retry
                else
                    raise FourChanPostError, "Could not post. (#{exc})"
                end
            end
            @logger.debug("Successfully posted!")
        end

        def get_random_reply(board)
            thread = get_random_thread(board)
            return thread.replies.sample
        end

        def get_random_thread(board)
            thread_numbers = @client.get_threads(board)
            return @client.get_thread(board, thread_numbers.sample().number)
        end

        attr_accessor :posts_made
    end
end
