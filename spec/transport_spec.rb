require "lygens/http/transport"
require "rest-client"

RSpec.describe Lygens::Http::RestClientTransport do
    before(:each) do
        @transport = Lygens::Http::RestClientTransport.new
        @params = {
            method: :get,
            url: "test.se"
        }
        @response = instance_double("RestClient::Response")
    end

    describe "#adapt_params" do
        context "when given hash with method and url" do
            it "should return a hash with url and method" do
                expect(@transport.adapt_params(@params)).to eq(@params)
            end
        end

        context "when given hash with headers" do
            it "should return a hash with headers" do
                expected = {
                    method: :get,
                    url: "test.se",
                    headers: {
                        Host: "test.se"
                    }
                }

                expect(@transport.adapt_params(expected)).to eq(expected)
            end
        end

        context "when given hash with params" do
            it "should return a hash with params" do
                given = {
                    method: :get,
                    url: "test.se",
                    params: {
                        test: "test"
                    }
                }

                expected = {
                    method: :get,
                    url: "test.se",
                    headers: {
                        params: {
                            test: "test"
                        }
                    }
                }

                expect(@transport.adapt_params(given)).to eq(expected)
            end
        end

        context "when given hash with payload" do
            it "should return a hash with payload" do
                expected = {
                    method: :get,
                    url: "test.se",
                    payload: {
                        test: "test"
                    }
                }

                expect(@transport.adapt_params(expected)).to eq(expected)
            end
        end

        context "when given hash without method or url" do
            it "should raise ArgumentError" do
                expect do
                    @transport.adapt_params(url: "test.se")
                end.to raise_error(ArgumentError)

                expect do
                    @transport.adapt_params(method: :get)
                end.to raise_error(ArgumentError)
            end
        end
    end

    describe "#adapt_response" do
        it "should adapt the response properly" do
            headers = {
                content_type: "application/json",
                host: "google.se"
            }
            cookies = {
                id: "test"
            }
            content = "[1, 2, 3]"

            allow(@response).to receive(:code).and_return(200)
            allow(@response).to receive(:headers).and_return(headers)
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
