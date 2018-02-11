require "lygens/http/transport"
require "lygens/http/request"
require "rest-client"

RSpec.describe Lyg::RestClientHttpTransport do
    before(:each) do
        @request = Lyg::HttpRequest.new(:get, "test.se")
        @response = instance_double("RestClient::Response")
        @request_class = class_double("RestClient::Request")
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
                expect(resp.body).to eq(nil)
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
                expect(resp.body).to eq(nil)
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

        context "when given request with headers and cookies" do
            it "should return a hash with headers and cookies" do
                @request.headers["Content-Type"] = "test"
                @request.cookies["test"] = "yes"

                expected = {
                    method: :get,
                    url: "test.se",
                    headers: {
                        "Content-Type" => "test",
                        params: {}
                    },
                    cookies: {
                        "test" => "yes"
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
            content = "[1, 2, 3]"

            allow(@response).to receive(:code).and_return(200)
            allow(@response).to receive(:raw_headers).and_return(headers)
            allow(@response).to receive(:cookies).and_return(cookies)
            allow(@response).to receive(:body).and_return(content)

            result = @transport.adapt_response(@response)
            expect(result.code).to eq(200)
            expect(result.headers).to eq(headers)
            expect(result.cookies).to eq(cookies)
            expect(result.body).to eq(content)
        end
    end
end
