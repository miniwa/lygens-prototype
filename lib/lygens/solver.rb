require "logging"

module Lyg
    class LygensCaptchaSolver
        def initialize(captcha_client)
            @captcha_client = captcha_client
            @site = "https://boards.4chan.org/v"
            @site_key = "6Ldp2bsSAAAAAAJ5uyx_lx34lJeEpTLVkP5k04qc"
            @logger = Logging.logger[self]
        end

        def get_answer
            begin
                @logger.debug("Creating recaptcha task..")
                task_id = @captcha_client.create_recaptcha_task(@site, @site_key)
                @logger.debug("Task #{task_id} created.")
                sleep(1)
    
                tries = 0
                while tries < 40
                    tries += 1
                    @logger.debug("Fetching status of captcha task..")
                    response = @captcha_client.get_recaptcha_result(task_id)
                    if response.is_ready
                        @logger.debug("Answer ready: #{response.answer}")
                        return response.answer
                    end
    
                    @logger.debug("Captcha task pending. Sleeping 5 seconds..")
                    sleep(5)
                end
            rescue StandardError => exc
                @logger.warn("Unhandled exception when fetching captcha:"\
                "(#{exc.class} #{exc.message}) #{exc.backtrace}")
                raise exc
            end

            raise StandardError, "Captcha task timed out"
        end

        def get_answer_async(executor)
            return Concurrent::Promise.new(executor: executor) do
                get_answer
            end
        end
    end
end
