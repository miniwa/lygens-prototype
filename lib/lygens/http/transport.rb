require "lygens/http/error"

module Lyg
    # This class represents an abstract http transport
    class HttpTransport
        # Executes the given +HttpRequest+
        def execute(_request)
            raise NotImplementedError, "Abstract execute called"
        end
    end

    # This class represents a http transport imlpementation using the
    # rest-client library
    class RestClientHttpTransport < HttpTransport
        # Initializes the transport with the given request api
        def initialize(request_class = RestClient::Request)
            @request_class = request_class
        end

        # Returns the given +HttpRequest+ as a hash in a format rest-client
        # expects
        def adapt_request(request)
            if request.url.nil? || request.method.nil?
                raise ArgumentError, "Url and method are required"
            end

            params = {
                method: request.method,
                url: request.url,
                headers: request.headers,
                cookies: request.cookies
            }

            unless request.content.nil?
                if request.content.is_a?(HttpMultiPartContent)
                    params[:payload] = request.content.parts
                        .merge(multipart: true)
                else
                    params[:payload] = request.content.as_text
                    request.content.get_headers.each do |key, value|
                        unless params[:headers].key?(key)
                            params[:headers][key] = value
                        end
                    end
                end
            end

            params[:headers][:params] = request.parameters

            return params
        end

        # Returns the given rest-client response as a +HttpResponse+.
        def adapt_response(response)
            formatted = Lyg::HttpResponse.new(response.code)

            response.raw_headers.each do |key, value|
                formatted.headers[key] = value
            end

            response.cookies.each do |key, value|
                formatted.cookies[key] = value
            end

            formatted.content = response.body
            return formatted
        end

        # Executes a given +HttpRequest+ and returns the +HttpResponse+
        def execute(request)
            begin
                response = @request_class.execute(adapt_request(request))
                return adapt_response(response)
            rescue RestClient::ExceptionWithResponse => e
                return adapt_response(e.response)
            rescue RestClient::Exception
                raise HttpConnectionError, "A transport error has occured"
            end
        end
    end
end
