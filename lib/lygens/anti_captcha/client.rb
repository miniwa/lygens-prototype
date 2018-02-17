require "lygens/anti_captcha/error"
require "lygens/http/client"
require "lygens/http/request"
require "lygens/http/response"
require "lygens/model/parser"
require "lygens/http/content"

module Lyg
    # A client to the anti captcha api
    class AntiCaptchaClient < HttpClient
        def initialize(transport, key, host = "https://api.anti-captcha.com")
            @host = host
            @key = key
            super(transport)
        end

        # Creates a new recaptcha task for the site with given url and key
        def create_recaptcha_task(url, site_key)
            parameters = {
                "clientKey" => @key,
                "task": {
                    "type" => "NoCaptchaTaskProxyless",
                    "websiteURL" => url,
                    "websiteKey" => site_key
                }
            }

            request = HttpRequest.new(:post, "#{@host}/createTask")
            request.content = HttpJsonContent.new(parameters)

            dto = execute(request).parse_as(CreateTaskDto)
            check_error_status(dto)

            return dto.task_id
        end

        # Polls the status of a recaptcha task with given id
        def get_recaptcha_result(task_id)
            parameters = {
                "clientKey" => @key,
                "taskId" => task_id
            }

            request = HttpRequest.new(:post, "#{@host}/getTaskResult")
            request.content = HttpJsonContent.new(parameters)
            dto = execute(request).parse_as(GetTaskResultDto)
            check_error_status(dto)

            result = AntiCaptchaRecaptchaResult.new
            if dto.status == "ready"
                result.is_ready = true
                result.answer = dto.solution["gRecaptchaResponse"]
            else
                result.is_ready = false
            end

            return result
        end

        def execute(request)
            begin
                response = super(request)
            rescue HttpConnectionError => exc
                raise AntiCaptchaError, "HTTP request failed. (#{exc})"
            end

            if response.code != 200
                raise AntiCaptchaError, "HTTP code #{response.code} received"
            end
            response.parser = JsonParser.new

            return response
        end

        def check_error_status(dto)
            if dto.error_id > 1
                raise AntiCaptchaError, "API call failed with code:"\
                " #{dto.error_code} (#{dto.error_description})"
            end
        end

        attr_accessor :host, :key
    end

    # A result object returned when calling #get_recaptcha_result
    class AntiCaptchaRecaptchaResult
        attr_accessor :is_ready, :answer
    end

    CreateTaskDto = Lyg::Model.define do
        field :task_id do
            key "taskId"
        end

        field :error_id do
            key "errorId"
        end
        
        field :error_code do
            key "errorCode"
        end

        field :error_description do
            key "errorDescription"
        end
    end

    GetTaskResultDto = Lyg::Model.define do
        field :error_id do
            key "errorId"
        end
        
        field :error_code do
            key "errorCode"
        end

        field :error_description do
            key "errorDescription"
        end

        field :solution
        field :status
        field :cost
        field :ip
    end
end
