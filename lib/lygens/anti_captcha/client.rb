require "lygens/anti_captcha/error"
require "lygens/http/client"
require "lygens/http/request"
require "lygens/http/response"
require "lygens/model/parser"
require "lygens/http/content"

module Lyg
    class AntiCaptchaClient < HttpClient
        def initialize(transport, key, host = "https://api.anti-captcha.com")
            @host = host
            @key = key
            super(transport)
        end

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
            response = @transport.execute(request)
            response.parser = JsonParser.new

            if response.code != 200
                raise AntiCaptchaError,
                    "The http request could not be completed"
            end

            dto = response.parse_as(CreateTaskDto)
            if dto.error_id > 1
                raise AntiCaptchaError, "API call failed with code:"\
                " #{dto.error_code} (#{dto.error_description})"
            end

            return dto.task_id
        end

        def get_recaptcha_result(task_id)
            parameters = {
                "clientKey" => @key,
                "taskId" => task_id
            }

            request = HttpRequest.new(:post, "#{@host}/getTaskResult")
            request.content = HttpJsonContent.new(parameters)
            response = @transport.execute(request)
            response.parser = JsonParser.new

            if response.code != 200
                raise AntiCaptchaError,
                    "The http request could not be completed"
            end

            dto = response.parse_as(GetTaskResultDto)
            if dto.error_id > 1
                raise AntiCaptchaError, "API call failed with code:"\
                " #{dto.error_code} (#{dto.error_description})"
            end

            result = AntiCaptchaRecaptchaResult.new
            if dto.status == "ready"
                result.is_ready = true
                result.answer = dto.solution["gRecaptchaResponse"]
            else
                result.is_ready = false
            end

            return result
        end

        attr_accessor :host, :key
    end

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
