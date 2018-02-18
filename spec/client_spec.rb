require "lygens/http/client"

RSpec.describe Lyg::HttpClient do
    before(:each) do
        @transport = instance_double("Lyg::HttpTransport")
        @client = Lyg::HttpClient.new(@transport)
        @response = Lyg::HttpResponse.new(200)
        @request = Lyg::HttpRequest.new(:get, "test.se")
    end

    describe "#execute" do
        context "when called with only url and method" do
            it "should call the transport with only those parameters" do
                allow(@transport).to receive(:execute).and_return(@response)
                @client.execute(@request)
                expect(@transport).to have_received(:execute)
                    .with(@request)
            end
        end

        context "when called with preset header, cookie or proxy" do
            it "should include those objects in the request" do
                @client.headers["Host"] = "google.se"
                @client.cookies["cfid"] = "test"
                @client.proxy = "http://test.se:80"
                allow(@transport).to receive(:execute).and_return(@response)

                @client.execute(@request)
                expect(@transport).to have_received(:execute)
                    .with(@request)

                expect(@request.headers["Host"]).to eq("google.se")
                expect(@request.cookies["cfid"]).to eq("test")
                expect(@request.proxy).to eq("http://test.se:80")
            end
        end

        context "when called with both preset and argument headers or"\
        " cookies" do
            it "should prioritize the argument" do
                @client.headers["Host"] = "google.se"
                @client.cookies["cfid"] = "test"
                @client.proxy = "http://test.se:80"
                allow(@transport).to receive(:execute).and_return(@response)

                @request.headers["Host"] = "testest"
                @request.cookies["cfid"] = "id"
                @request.proxy = "http://test.se:8080"

                @client.execute(@request)
                expect(@transport).to have_received(:execute)
                    .with(@request)

                expect(@request.headers["Host"]).to eq("testest")
                expect(@request.cookies["cfid"]).to eq("id")
                expect(@request.proxy).to eq("http://test.se:8080")
            end
        end

        context "when autosave_cookies is enabled" do
            it "should automatically save cookies from the response" do
                @client.autosave_cookies = true
                @response.cookies["id"] = "test"
                allow(@transport).to receive(:execute).and_return(@response)

                @client.execute(@request)
                expect(@client.cookies.length).to eq(1)
                expect(@client.cookies["id"]).to eq("test")
            end
        end
    end
end
