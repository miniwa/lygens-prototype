require "lygens/http/transport"
require "lygens/http/request"
require "lygens/http/content"
require "rest-client"

RSpec.describe Lyg::RestClientHttpTransport do
    before(:each) do
        @request = Lyg::HttpRequest.new(:get, "test.se")
        @response = instance_double("RestClient::Response")
        @request_class = class_double("RestClient::Request")
        @content = instance_double("Lyg::HttpJsonContent")
        @transport = Lyg::RestClientHttpTransport.new(@request_class)
    end

    describe "#execute" do
        context "when no error occurs" do
            it "should return a normal response" do
                allow(@response).to receive(:code).and_return(200)
                allow(@response).to receive(:raw_headers).and_return({})
                allow(@response).to receive(:cookies).and_return({})
                allow(@response).to receive(:body).and_return(nil)

                allow(@request_class).to receive(:execute).and_return(@response)

                resp = @transport.execute(@request)
                expect(resp.code).to eq(200)
                expect(resp.headers).to eq({})
                expect(resp.cookies).to eq({})
                expect(resp.content).to eq(nil)
            end
        end

        context "when http error occurs" do
            it "should return a normal response" do
                allow(@response).to receive(:code).and_return(404)
                allow(@response).to receive(:raw_headers).and_return({})
                allow(@response).to receive(:cookies).and_return({})
                allow(@response).to receive(:body).and_return(nil)

                error = RestClient::ExceptionWithResponse.new(@response)
                allow(@request_class).to receive(:execute).and_raise(error)

                resp = @transport.execute(@request)
                expect(resp.code).to eq(404)
                expect(resp.headers).to eq({})
                expect(resp.cookies).to eq({})
                expect(resp.content).to eq(nil)
            end
        end

        context "when a transport error occurs" do
            it "should raise ConnectionError" do
                allow(@request_class).to receive(:execute).and_raise(
                    RestClient::Exception
                )

                expect do
                    @transport.execute(@request)
                end.to raise_error(Lyg::HttpConnectionError)
            end
        end

        context "when an unknown error occurs" do
            it "should let the error pass" do
                allow(@request_class).to receive(:execute).and_raise(
                    IndexError
                )

                expect do
                    @transport.execute(@request)
                end.to raise_error(IndexError)
            end
        end
    end

    describe "#adapt_request" do
        context "when given a request with method and url" do
            it "should return a hash with url and method" do
                expected = {
                    method: :get,
                    url: "test.se",
                    headers: {
                        params: {}
                    },
                    cookies: {}
                }
                expect(@transport.adapt_request(@request)).to eq(expected)
            end
        end

        context "when given request with headers, cookies and proxy" do
            it "should return a hash with headers, cookies and content" do
                allow(@content).to receive(:as_text).and_return("[1,2]")
                allow(@content).to receive(:get_headers).and_return(
                    "Content-Type" => "application/json")

                @request.headers["Host"] = "test"
                @request.cookies["test"] = "yes"
                @request.proxy = "http://test.se:8080"
                @request.content = @content

                expected = {
                    method: :get,
                    url: "test.se",
                    headers: {
                        "Content-Type" => "application/json",
                        "Host" => "test",
                        params: {}
                    },
                    cookies: {
                        "test" => "yes"
                    },
                    payload: "[1,2]",
                    proxy: "http://test.se:8080"
                }

                expect(@transport.adapt_request(@request)).to eq(expected)
            end
        end

        context "when given request with multipart content" do
            it "should set all its part and flag the content as multipart" do
                content = Lyg::HttpMultiPartContent.new
                content.parts = {
                    "alive" => "yes",
                    "reply_to" => 0
                }
                @request.content = content

                expected = {
                    method: :get,
                    url: "test.se",
                    headers: {
                        params: {}
                    },
                    cookies: {},
                    payload: {
                        "alive" => "yes",
                        "reply_to" => 0,
                        multipart: true
                    }
                }

                expect(@transport.adapt_request(@request)).to eq(expected)
            end
        end

        context "when given request with parameters" do
            it "should return a hash with params in the header" do
                @request.parameters["test"] = 10
                expected = {
                    method: :get,
                    url: "test.se",
                    headers: {
                        params: {
                            "test" => 10
                        }
                    },
                    cookies: {}
                }

                expect(@transport.adapt_request(@request)).to eq(expected)
            end
        end
    end

    describe "#adapt_response" do
        it "should adapt the response properly" do
            headers = {
                "Content-Type" => "application/json",
                "Host" => "google.se"
            }
            cookies = {
                "id" => "test"
            }
            body = "[1, 2, 3]"

            allow(@response).to receive(:code).and_return(200)
            allow(@response).to receive(:raw_headers).and_return(headers)
            allow(@response).to receive(:cookies).and_return(cookies)
            allow(@response).to receive(:body).and_return(body)

            result = @transport.adapt_response(@response)
            expect(result.code).to eq(200)
            expect(result.headers).to eq(headers)
            expect(result.cookies).to eq(cookies)
            expect(result.content).to eq(body)
        end
    end
end
