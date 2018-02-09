require "lygens/http/error"

module Lyg
    # This class represents an abstract http transport
    class HttpTransport
        # Makes a http request with the given parameters. The hash may
        # contain the following values:
        # * +url+ - The url to make the request to.
        # * +method+ - The method to use when making the request.
        # * +headers+ - A hash containing a set of headers.
        # * +params+ - A hash containing a set of query parameters.
        # * +payload+ - A hash containing a set of payloads.
        def make_request(params)
            raise NotImplementedError, "Abstract make_request"\
                "called with: #{params}"
        end
    end

    # This class represents a http transport imlpementation using the
    # rest-client library
    class RestClientHttpTransport < HttpTransport
        # Initializes the transport with the given request api
        def initialize(request_class = RestClient::Request)
            @request_class = request_class
        end

        # Returns the given hash of arguments as a hash in a format
        # rest-client expects.
        def adapt_params(params)
            unless params.key?(:url) && params.key?(:method)
                raise ArgumentError, "Url and method are required"
            end

            actual_params = {
                method: params[:method],
                url: params[:url]
            }

            if params.key?(:headers)
                actual_params[:headers] = params[:headers]
            end

            if params.key?(:params)
                unless actual_params.key?(:headers)
                    actual_params[:headers] = {}
                end
                actual_params[:headers][:params] = params[:params]
            end

            if params.key?(:payload)
                actual_params[:payload] = params[:payload]
            end

            return actual_params
        end

        # Returns the given rest-client response as a +HttpResponse+.
        def adapt_response(response)
            formatted = Lyg::HttpResponse.new(response.code)

            response.headers.each do |key, value|
                formatted.headers[key] = value
            end

            response.cookies.each do |key, value|
                formatted.cookies[key] = value
            end

            formatted.body = response.body
            return formatted
        end

        # Makes a http request with the given parameters. The hash may
        # contain the following values:
        # * +url+ - The url to make the request to.
        # * +method+ - The method to use when making the request.
        # * +headers+ - A hash containing a set of headers.
        # * +params+ - A hash containing a set of query parameters.
        # * +payload+ - A hash containing a set of payloads.
        def make_request(params)
            begin
                response = @request_class.execute(adapt_params(params))
                return adapt_response(response)
            rescue RestClient::ExceptionWithResponse => e
                return adapt_response(e.response)
            rescue RestClient::Exception
                raise HttpConnectionError, "A transport error has occured"
            end
        end
    end
end
